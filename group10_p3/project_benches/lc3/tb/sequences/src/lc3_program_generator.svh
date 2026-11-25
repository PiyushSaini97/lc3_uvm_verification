// lc3_program_generator
// Produces the instruction stream, one word per instruction fetch.
//
// WHY A STREAM, NOT AN ADDRESS MAP
//   This controller never fetches down a wrong path: it stops fetching while a
//   branch or JMP is in the pipeline and fetches the target next. So the order in
//   which instruction memory is asked for words IS the execution order, and the
//   generator can lay out multi-instruction "snippets" (producer then consumer,
//   psr setter then branch, ...) knowing they execute back to back. It also means
//   backward branches and jumps to old addresses cannot trap the test in a loop:
//   every fetch gets a fresh word.
//
// The register-clearing prologue is not produced here: imem_responder_sequence
// sends it before asking for the first generated word.
//
// SNIPPETS and the coverage they target (see README for the full map):
//   RANDOM      any legal instruction, all fields random   -> opcode/register crosses
//   HAZARD      producer (ALU or load) -> consumer reading its result through sr1,
//               sr2 or both, 0-2 instructions apart      -> every bypass path per opcode,
//                                                            imem dependency_cg
//   BRANCH      set psr to N, Z or P, then BR with any condition and either offset
//               sign                                       -> nzp x psr, br_taken both ways
//   CONST       build 0000/0001/7FFF/8000/FFFE/FFFF in a register and use it
//                                                          -> aluout/vsr/M_Data corners
//   JUMP        JMP to 0000/7FFF/8000/FFFE/FFFF, then PC-relative instructions that
//               land on address/result 0000 or FFFF        -> npc/pcout corners, LEA zero
//                                                             and negative results
//   MEM_CORNER  base register 0000/FFFF with LDR/STR, stores of corner values
//                                                          -> M_Addr/Data_addr/M_Data corners
//   INDIRECT    LDI/STI (pointers come from data memory)   -> FSM 3-1-0-3 / 3-1-2-3,
//                                                             indirect pointer corners
//   BYPASS_DIST producer of any class, 0-2 fillers, consumer -> bypass_sr1_cg, bypass_sr2_cg
//   DUAL        two producers, then one instruction reading both -> mixed_bypass_cg
//   CHAIN       producer followed by 2-6 dependent ALU instructions -> chain_cg
//   MEM_BURST   2-6 memory instructions, 0-2 ALU between      -> mem_pair_cg, mem_run_cg
//   BRANCH_HIST writer of any class, 0-3 NOPs, BR            -> branch_history_cg
//   WAW         two writers of the same register             -> waw_cg
typedef enum int {
  SNIP_RANDOM,
  SNIP_HAZARD,
  SNIP_BRANCH,
  SNIP_CONST,
  SNIP_JUMP,
  SNIP_MEM_CORNER,
  SNIP_INDIRECT,
  SNIP_BYPASS_DIST,
  SNIP_DUAL,
  SNIP_CHAIN,
  SNIP_MEM_BURST,
  SNIP_BRANCH_HIST,
  SNIP_WAW
} lc3_snippet_e;

class lc3_program_generator extends uvm_object;
  `uvm_object_utils(lc3_program_generator)

  localparam int NUM_SNIPPETS = 13;

  // Relative weights, indexed by lc3_snippet_e. Tests may change them.
  int unsigned         weight        [NUM_SNIPPETS]  = '{30, 25, 15, 8, 6, 8, 8, 18, 8, 8, 10, 14, 6};

  int unsigned         snippet_count [NUM_SNIPPETS];
  int unsigned         words_emitted;

  protected bit [15:0] pending       [           $];

  function new(string name = "lc3_program_generator");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------
  function bit [15:0] next();
    bit [15:0] w;
    if (pending.size() == 0) refill();
    w = pending.pop_front();
    if (!lc3_isa::is_legal(w))
      `uvm_fatal("LC3_GEN", $sformatf("generator produced an illegal word 0x%4h", w));
    words_emitted++;
    return w;
  endfunction

  // "30,25,15,8,6,8,8,18,8,8,10,14,6" -> weights in lc3_snippet_e order (missing entries keep
  // their value). Used for the +LC3_MIX plusarg.
  function void apply_mix(string mix);
    int unsigned idx = 0;
    string       field = "";
    for (int i = 0; i <= mix.len(); i++) begin
      if (i == mix.len() || mix[i] == ",") begin
        if (field != "" && idx < NUM_SNIPPETS) weight[idx] = field.atoi();
        idx++;
        field = "";
      end else field = {field, mix.substr(i, i)};
    end
  endfunction

  // Reads +LC3_MIX=<w0,...,w12> if present.
  function void apply_plusargs();
    string mix;
    if ($value$plusargs("LC3_MIX=%s", mix)) apply_mix(mix);
  endfunction

  function string summary();
    lc3_snippet_e s;
    string        r = $sformatf("%0d instructions:", words_emitted);
    for (int i = 0; i < NUM_SNIPPETS; i++) begin
      s = lc3_snippet_e'(i);
      r = {r, $sformatf(" %s=%0d", s.name(), snippet_count[i])};
    end
    return r;
  endfunction

  // ---------------------------------------------------------------------------
  // Random field helpers
  // ---------------------------------------------------------------------------
  protected function bit [2:0] rreg();
    return 3'($urandom_range(0, 7));
  endfunction

  protected function bit [2:0] rreg_except(bit [2:0] r);
    bit [2:0] x;
    do x = rreg(); while (x == r);
    return x;
  endfunction

  // A register other than a and b.
  protected function bit [2:0] rreg_not2(bit [2:0] a, bit [2:0] b);
    bit [2:0] x;
    do x = rreg(); while (x == a || x == b);
    return x;
  endfunction

  // imm5 biased to the values that create result corners: 0, 1, -1, 15, -16.
  protected function bit [4:0] rimm5();
    case ($urandom_range(
        0, 9
    ))
      0:       return 5'h00;
      1:       return 5'h01;
      2:       return 5'h1f;
      3:       return 5'h0f;
      4:       return 5'h10;
      default: return 5'($urandom);
    endcase
  endfunction

  // PC/base offsets with an even split of signs (offset_cg needs both).
  protected function bit [8:0] roff9();
    bit [8:0] o = 9'($urandom);
    o[8] = $urandom_range(0, 1);
    return o;
  endfunction

  protected function bit [5:0] roff6();
    bit [5:0] o = 6'($urandom);
    o[5] = $urandom_range(0, 1);
    return o;
  endfunction

  // Offset that makes (pc + 1 + off) == want, if it fits in 9 signed bits.
  protected function bit fit_off9(bit [15:0] pc, bit [15:0] want, output bit [8:0] off);
    int d = $signed(16'(want - (pc + 16'd1)));
    off = 9'(d);
    return (d >= -256) && (d <= 255);
  endfunction

  // ---------------------------------------------------------------------------
  // Instruction builders
  // ---------------------------------------------------------------------------
  // Random ADD/AND (either mode) or NOT writing dr.
  protected function bit [15:0] alu_into(bit [2:0] dr);
    case ($urandom_range(
        0, 4
    ))
      0:       return lc3_isa::add_r(dr, rreg(), rreg());
      1:       return lc3_isa::add_i(dr, rreg(), rimm5());
      2:       return lc3_isa::and_r(dr, rreg(), rreg());
      3:       return lc3_isa::and_i(dr, rreg(), rimm5());
      default: return lc3_isa::not_r(dr, rreg());
    endcase
  endfunction

  // Random load writing dr.
  protected function bit [15:0] load_into(bit [2:0] dr);
    case ($urandom_range(
        0, 2
    ))
      0:       return lc3_isa::ld(dr, roff9());
      1:       return lc3_isa::ldr(dr, rreg(), roff6());
      default: return lc3_isa::ldi(dr, roff9());
    endcase
  endfunction

  // Producer of the requested class writing dr: 0 ALU, 1 load, 2 LEA.
  protected function bit [15:0] producer_into(int cls, bit [2:0] dr);
    case (cls)
      0:       return alu_into(dr);
      1:       return load_into(dr);
      default: return lc3_isa::lea(dr, roff9());
    endcase
  endfunction

  // ADD/AND/NOT that reads src through sr1 (slot 0) or sr2 (slot 1) and writes dr,
  // so a chain of them keeps depending on the one before.
  protected function bit [15:0] alu_consumer(bit [2:0] src, bit [2:0] dr, int slot);
    bit [2:0] o = rreg_except(src);
    if (slot == 0) begin
      case ($urandom_range(0, 4))
        0:       return lc3_isa::add_r(dr, src, o);
        1:       return lc3_isa::add_i(dr, src, rimm5());
        2:       return lc3_isa::and_r(dr, src, o);
        3:       return lc3_isa::and_i(dr, src, rimm5());
        default: return lc3_isa::not_r(dr, src);
      endcase
    end
    else begin
      if ($urandom_range(0, 1)) return lc3_isa::add_r(dr, o, src);
      else return lc3_isa::and_r(dr, o, src);
    end
  endfunction

  // Memory instruction of kind 0 LD, 1 LDR, 2 LDI, 3 ST, 4 STR, 5 STI.
  protected function bit [15:0] mem_of_kind(int kind);
    case (kind)
      0:       return lc3_isa::ld(rreg(), roff9());
      1:       return lc3_isa::ldr(rreg(), rreg(), roff6());
      2:       return lc3_isa::ldi(rreg(), roff9());
      3:       return lc3_isa::st(rreg(), roff9());
      4:       return lc3_isa::str(rreg(), rreg(), roff6());
      default: return lc3_isa::sti(rreg(), roff9());
    endcase
  endfunction

  // Any of the 12 opcodes, uniformly, all fields random.
  protected function bit [15:0] random_instr();
    bit [15:0] w;
    case ($urandom_range(
        0, 11
    ))
      0: begin
        w = lc3_isa::br(3'($urandom), roff9());
        if (w == 16'h0000) w = lc3_isa::nop();
      end
      1:
      w = $urandom_range(0, 1) ? lc3_isa::add_r(rreg(), rreg(), rreg()) :
          lc3_isa::add_i(rreg(), rreg(), rimm5());
      2: w = lc3_isa::ld(rreg(), roff9());
      3: w = lc3_isa::st(rreg(), roff9());
      4:
      w = $urandom_range(0, 1) ? lc3_isa::and_r(rreg(), rreg(), rreg()) :
          lc3_isa::and_i(rreg(), rreg(), rimm5());
      5: w = lc3_isa::ldr(rreg(), rreg(), roff6());
      6: w = lc3_isa::str(rreg(), rreg(), roff6());
      7: w = lc3_isa::not_r(rreg(), rreg());
      8: w = lc3_isa::ldi(rreg(), roff9());
      9: w = lc3_isa::sti(rreg(), roff9());
      10: w = lc3_isa::jmp(rreg());
      default: w = lc3_isa::lea(rreg(), roff9());
    endcase
    return w;
  endfunction

  // An instruction that reads `src` in the requested slot.
  //   slot 0 = sr1 only, 1 = sr2 only, 2 = both
  // sr1 readers: ADD/AND (either mode), NOT, LDR base, STR base, JMP base
  // sr2 readers: ADD/AND register mode, ST/STR/STI source
  protected function bit [15:0] consumer(bit [2:0] src, int slot);
    bit [2:0] o = rreg_except(src);  // the other operand, so only `src` is dependent
    case (slot)
      0:
      case ($urandom_range(
          0, 6
      ))
        0: return lc3_isa::add_r(rreg(), src, o);
        1: return lc3_isa::add_i(rreg(), src, rimm5());
        2: return lc3_isa::and_r(rreg(), src, o);
        3: return lc3_isa::and_i(rreg(), src, rimm5());
        4: return lc3_isa::not_r(rreg(), src);
        5: return $urandom_range(0, 1) ? lc3_isa::ldr(rreg(), src, roff6()) : lc3_isa::str(o, src, roff6());
        default: return lc3_isa::jmp(src);
      endcase
      1:
      case ($urandom_range(
          0, 4
      ))
        0:       return lc3_isa::add_r(rreg(), o, src);
        1:       return lc3_isa::and_r(rreg(), o, src);
        2:       return lc3_isa::st(src, roff9());
        3:       return lc3_isa::str(src, o, roff6());
        default: return lc3_isa::sti(src, roff9());
      endcase
      default:
      case ($urandom_range(
          0, 2
      ))
        0:       return lc3_isa::add_r(rreg(), src, src);
        1:       return lc3_isa::and_r(rreg(), src, src);
        default: return lc3_isa::str(src, src, roff6());
      endcase
    endcase
  endfunction

  // Emit code that leaves `value` in register r. Returns nothing; the code is
  // appended to `pending`.
  protected function void emit_const(bit [2:0] r, bit [15:0] value);
    pending.push_back(lc3_isa::and_i(r, r, 5'h00));  // r = 0
    case (value)
      16'h0000: ;
      16'h0001: pending.push_back(lc3_isa::add_i(r, r, 5'h01));
      16'hffff: pending.push_back(lc3_isa::not_r(r, r));
      16'hfffe: pending.push_back(lc3_isa::add_i(r, r, 5'h1e));  // 0 + (-2)
      16'h8000, 16'h7fff: begin
        pending.push_back(lc3_isa::add_i(r, r, 5'h01));  // 1
        repeat (15) pending.push_back(lc3_isa::add_r(r, r, r));  // 1 << 15 = 8000
        if (value == 16'h7fff) pending.push_back(lc3_isa::not_r(r, r));
      end
      default:  `uvm_fatal("LC3_GEN", $sformatf("emit_const: unsupported value 0x%4h", value))
    endcase
  endfunction

  protected function bit [15:0] rcorner();
    case ($urandom_range(
        0, 5
    ))
      0:       return 16'h0000;
      1:       return 16'h0001;
      2:       return 16'h7fff;
      3:       return 16'h8000;
      4:       return 16'hfffe;
      default: return 16'hffff;
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // Snippets
  // ---------------------------------------------------------------------------
  protected function void snip_random();
    repeat ($urandom_range(1, 4)) pending.push_back(random_instr());
  endfunction

  protected function void snip_hazard();
    bit [2:0] dr = rreg();
    bit       load = ($urandom_range(0, 9) < 4);
    int       gap = ($urandom_range(0, 9) < 7) ? 0 : $urandom_range(1, 2);
    pending.push_back(load ? load_into(dr) : alu_into(dr));
    // Fillers between producer and consumer must not overwrite dr.
    repeat (gap) pending.push_back(alu_into(rreg_except(dr)));
    pending.push_back(consumer(dr, $urandom_range(0, 2)));
  endfunction

  protected function void snip_branch();
    bit [2:0] r = rreg();
    bit [2:0] nzp;
    bit [8:0] off;
    pending.push_back(lc3_isa::and_i(r, r, 5'h00));  // psr = Z
    case ($urandom_range(
        0, 2
    ))
      0:       pending.push_back(lc3_isa::not_r(r, r));  // FFFF: psr = N
      1:       ;  // stays Z
      default: pending.push_back(lc3_isa::add_i(r, r, 5'h01));  // 1:    psr = P
    endcase
    // 0-2 NOPs so the setter has written back before the branch resolves.
    repeat ($urandom_range(0, 2)) pending.push_back(lc3_isa::nop());
    nzp = 3'($urandom);
    off = roff9();
    if (nzp == 3'b000 && off == 9'd0) off = 9'd1;  // never 0x0000
    pending.push_back(lc3_isa::br(nzp, off));
  endfunction

  protected function void snip_const();
    bit [ 2:0] r = rreg();
    bit [15:0] v = rcorner();
    emit_const(r, v);
    // Use it: as an ALU operand (aluout/vsr corners) or as store data (M_Data).
    case ($urandom_range(
        0, 3
    ))
      0:       pending.push_back(lc3_isa::add_i(rreg(), r, 5'h00));  // aluout = v
      1:       pending.push_back(lc3_isa::and_r(rreg(), r, r));  // aluout = v
      2:       pending.push_back(lc3_isa::st(r, roff9()));  // M_Data = v
      default: pending.push_back(lc3_isa::str(r, rreg_except(r), roff6()));
    endcase
  endfunction

  protected function void snip_jump();
    bit [ 2:0] r = rreg();
    bit [15:0] target;
    bit [15:0] pc;
    bit [ 8:0] off;
    case ($urandom_range(
        0, 4
    ))
      0:       target = 16'h0000;
      1:       target = 16'h7fff;
      2:       target = 16'h8000;
      3:       target = 16'hfffe;
      default: target = 16'hffff;
    endcase
    emit_const(r, target);
    pending.push_back(lc3_isa::jmp(r));
    // Code at the target. The next fetch after JMP is the target, so instruction i
    // of this block sits at pc = target + i and its npc is target + i + 1.
    pc = target;
    // LEA whose result is 0000 (zero class) where reachable, else FFFF/negative.
    if (fit_off9(pc, 16'h0000, off)) pending.push_back(lc3_isa::lea(rreg(), off));
    else pending.push_back(lc3_isa::lea(rreg(), roff9()));
    pc++;
    // Direct loads/stores whose address is a corner.
    if (fit_off9(pc, 16'hffff, off)) pending.push_back(lc3_isa::ld(rreg(), off));
    else pending.push_back(lc3_isa::ld(rreg(), roff9()));
    pc++;
    if (fit_off9(pc, 16'h0000, off)) pending.push_back(lc3_isa::st(rreg(), off));
    else pending.push_back(lc3_isa::st(rreg(), roff9()));
    pc++;
    // LEA with a negative result (high address region) or reaching FFFF.
    if (fit_off9(pc, 16'hffff, off)) pending.push_back(lc3_isa::lea(rreg(), off));
    else pending.push_back(lc3_isa::lea(rreg(), roff9()));
    // A little random code at the unusual PC.
    repeat ($urandom_range(1, 3)) pending.push_back(random_instr());
  endfunction

  protected function void snip_mem_corner();
    bit [ 2:0] base = rreg();
    bit [ 2:0] data = rreg_except(base);
    bit [15:0] a = $urandom_range(0, 1) ? 16'hffff : 16'h0000;
    emit_const(base, a);
    emit_const(data, rcorner());
    // Address exactly at the corner, and one step across it (wraps 0000 <-> FFFF).
    pending.push_back(lc3_isa::str(data, base, 6'd0));
    pending.push_back(lc3_isa::ldr(rreg_except(base), base, 6'd0));
    pending.push_back(lc3_isa::str(data, base, (a == 16'h0000) ? 6'h3f : 6'h01));
    pending.push_back(lc3_isa::ldr(rreg_except(base), base, (a == 16'h0000) ? 6'h3f : 6'h01));
  endfunction

  protected function void snip_indirect();
    repeat ($urandom_range(
        1, 3
    )) begin
      case ($urandom_range(
          0, 2
      ))
        0: pending.push_back(lc3_isa::ldi(rreg(), roff9()));
        1: pending.push_back(lc3_isa::sti(rreg(), roff9()));
        default: begin  // store a corner indirectly
          bit [2:0] r = rreg();
          emit_const(r, rcorner());
          pending.push_back(lc3_isa::sti(r, roff9()));
        end
      endcase
    end
  endfunction

  // Producer of every class, then a consumer 1, 2 or 3 instructions later.
  protected function void snip_bypass_dist();
    bit [2:0] dr  = rreg();
    int       gap = $urandom_range(0, 2);
    pending.push_back(producer_into($urandom_range(0, 2), dr));
    repeat (gap) pending.push_back(alu_into(rreg_except(dr)));
    pending.push_back(consumer(dr, $urandom_range(0, 2)));
  endfunction

  // Two producers, then one instruction that reads one register from each: both
  // operands bypassed at once, from different distances.
  protected function void snip_dual();
    bit [2:0] a = rreg();
    bit [2:0] b = rreg_except(a);
    bit [2:0] x, y;
    int       gaps = $urandom_range(0, 2);
    pending.push_back(producer_into($urandom_range(0, 2), a));
    if (gaps == 1) pending.push_back(alu_into(rreg_not2(a, b)));
    pending.push_back(producer_into($urandom_range(0, 2), b));
    if (gaps == 2) pending.push_back(alu_into(rreg_not2(a, b)));
    x = $urandom_range(0, 1) ? a : b;
    y = (x == a) ? b : a;
    case ($urandom_range(0, 2))
      0:       pending.push_back(lc3_isa::add_r(rreg(), x, y));
      1:       pending.push_back(lc3_isa::and_r(rreg(), x, y));
      default: pending.push_back(lc3_isa::str(y, x, roff6()));
    endcase
  endfunction

  // A producer followed by 2 to 6 ALU instructions, each reading the one before.
  protected function void snip_chain();
    bit [2:0] cur = rreg();
    bit [2:0] nxt;
    pending.push_back(producer_into($urandom_range(0, 2), cur));
    repeat ($urandom_range(2, 6)) begin
      nxt = rreg();
      pending.push_back(alu_consumer(cur, nxt, $urandom_range(0, 1)));
      cur = nxt;
    end
    if ($urandom_range(0, 2) == 0) pending.push_back(lc3_isa::str(cur, rreg(), roff6()));
  endfunction

  // 2 to 6 memory instructions of random kinds, separated by 0, 1 or 2 ALU instructions.
  protected function void snip_mem_burst();
    int n = $urandom_range(2, 6);
    int gap;
    for (int i = 0; i < n; i++) begin
      pending.push_back(mem_of_kind($urandom_range(0, 5)));
      if (i != n - 1) begin
        gap = ($urandom_range(0, 3) < 2) ? 0 : $urandom_range(1, 2);
        repeat (gap) pending.push_back(alu_into(rreg()));
      end
    end
  endfunction

  // A register writer of any class, 0 to 3 NOPs, then a BR with any condition. With 3 NOPs
  // the writer is out of the 3-instruction window, which is the "older" bin.
  protected function void snip_branch_hist();
    bit [2:0] nzp = 3'($urandom);
    bit [8:0] off = roff9();
    pending.push_back(producer_into($urandom_range(0, 2), rreg()));
    repeat ($urandom_range(0, 3)) pending.push_back(lc3_isa::nop());
    if (nzp == 3'b000 && off == 9'd0) off = 9'd1;  // never 0x0000
    pending.push_back(lc3_isa::br(nzp, off));
  endfunction

  // Two writers of the same register, 0 or 1 unrelated instruction apart.
  protected function void snip_waw();
    bit [2:0] dr = rreg();
    pending.push_back(producer_into($urandom_range(0, 2), dr));
    if ($urandom_range(0, 1)) pending.push_back(alu_into(rreg_except(dr)));
    pending.push_back(producer_into($urandom_range(0, 2), dr));
  endfunction

  // ---------------------------------------------------------------------------
  // Refill
  // ---------------------------------------------------------------------------
  protected function lc3_snippet_e pick();
    int unsigned total = 0, x;
    foreach (weight[i]) total += weight[i];
    if (total == 0) return SNIP_RANDOM;
    x = $urandom_range(0, total - 1);
    foreach (weight[i]) begin
      if (x < weight[i]) return lc3_snippet_e'(i);
      x -= weight[i];
    end
    return SNIP_RANDOM;
  endfunction

  protected function void refill();
    lc3_snippet_e s;
    s = pick();
    snippet_count[s]++;
    case (s)
      SNIP_RANDOM:      snip_random();
      SNIP_HAZARD:      snip_hazard();
      SNIP_BRANCH:      snip_branch();
      SNIP_CONST:       snip_const();
      SNIP_JUMP:        snip_jump();
      SNIP_MEM_CORNER:  snip_mem_corner();
      SNIP_INDIRECT:    snip_indirect();
      SNIP_BYPASS_DIST: snip_bypass_dist();
      SNIP_DUAL:        snip_dual();
      SNIP_CHAIN:       snip_chain();
      SNIP_MEM_BURST:   snip_mem_burst();
      SNIP_BRANCH_HIST: snip_branch_hist();
      default:          snip_waw();
    endcase
  endfunction
endclass : lc3_program_generator
