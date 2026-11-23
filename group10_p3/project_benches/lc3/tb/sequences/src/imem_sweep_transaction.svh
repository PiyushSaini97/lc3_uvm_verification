// imem_sweep_transaction
// Exhaustive sweep of every legal encoding counted by imem_coverage's
// exhaustive crosses: NUM_ENCODINGS = 37448 words. Each randomize() returns the
// next word of the sweep, so NUM_ENCODINGS consecutive responses cover all of
// them once, closing alu_imm_cg ... jmp_cg to 100% in the minimum number of
// fetches.
//
// ORDER
//   The encodings are visited in a random permutation (a shuffled index list,
//   reshuffled for every lap and seeded by the simulation seed). Each lap covers
//   every encoding exactly once, and consecutive words jump between formats and
//   opcodes, so hazards, branches and memory operations stay mixed as in random
//   code instead of 4096 ADDs in a row.
//
// WHY STATIC STATE
//   The responder creates a new transaction for every fetch, and the driver and
//   scoreboard may still hold earlier ones, so per-object state (randc) cannot be
//   used. The permutation and position are static, advanced in pre_randomize().
//   Objects the monitor creates through the same override are never randomized,
//   so they do not move the sweep.
//
// Encoding table (index ranges within one lap):
//   [    0, 4096)  ADD/AND imm5     op x DR x SR1 x imm5
//   [ 4096, 5120)  ADD/AND reg      op x DR x SR1 x SR2
//   [ 5120, 5184)  NOT              DR x SR
//   [ 5184,17472)  LD/LDI/LEA       op x DR x PCoffset9
//   [17472,21568)  LDR              DR x BaseR x offset6
//   [21568,29760)  ST/STI           op x SR x PCoffset9
//   [29760,33856)  STR              SR x BaseR x offset6
//   [33856,37440)  BR               nzp(001..111) x PCoffset9
//   [37440,37448)  JMP              BaseR
// lc3_sweep_test: imem_transaction::type_id::set_type_override(imem_sweep_transaction::get_type());
class imem_sweep_transaction extends imem_transaction;
  `uvm_object_utils(imem_sweep_transaction)

  localparam int unsigned NUM_ENCODINGS = 37448;

  static int unsigned issued;  // words handed out so far
  static int unsigned order[$];  // remaining encodings of the current lap

  bit [15:0] sweep_word;  // set in pre_randomize, imposed by sweep_c

  constraint sweep_c {
    data == sweep_word;
    opcode == sweep_word[15:12];
    immediate_mode == sweep_word[5];
  }

  function new(string name = "imem_sweep_transaction");
    super.new(name);
  endfunction

  // Encoding number idx (0 .. NUM_ENCODINGS-1) of the table above.
  static function bit [15:0] word_at(int unsigned idx);
    int unsigned i = idx;
    if (i < 4096) return {(i >= 2048) ? 4'b0101 : 4'b0001, 3'(i >> 8), 3'(i >> 5), 1'b1, 5'(i)};
    i -= 4096;
    if (i < 1024) return {(i >= 512) ? 4'b0101 : 4'b0001, 3'(i >> 6), 3'(i >> 3), 3'b000, 3'(i)};
    i -= 1024;
    if (i < 64) return {4'b1001, 3'(i >> 3), 3'(i), 6'b111111};
    i -= 64;
    if (i < 12288) begin
      bit [3:0] op;
      case (i / 4096)
        0:       op = 4'b0010;
        1:       op = 4'b1010;
        default: op = 4'b1110;
      endcase
      return {op, 3'(i >> 9), 9'(i)};
    end
    i -= 12288;
    if (i < 4096) return {4'b0110, 3'(i >> 9), 3'(i >> 6), 6'(i)};
    i -= 4096;
    if (i < 8192) return {(i >= 4096) ? 4'b1011 : 4'b0011, 3'(i >> 9), 9'(i)};
    i -= 8192;
    if (i < 4096) return {4'b0111, 3'(i >> 9), 3'(i >> 6), 6'(i)};
    i -= 4096;
    if (i < 3584) return {4'b0000, 3'(1 + i / 512), 9'(i)};
    i -= 3584;
    return {4'b1100, 3'b000, 3'(i), 6'b000000};
  endfunction

  function void pre_randomize();
    super.pre_randomize();
    if (order.size() == 0) begin
      for (int unsigned i = 0; i < NUM_ENCODINGS; i++) order.push_back(i);
      order.shuffle();
      `uvm_info("IMEM_SWEEP", $sformatf(
                "lap %0d: %0d encodings in random order", issued / NUM_ENCODINGS + 1, NUM_ENCODINGS),
                UVM_LOW);
    end
    sweep_word = word_at(order.pop_front());
    issued++;
  endfunction
endclass : imem_sweep_transaction
