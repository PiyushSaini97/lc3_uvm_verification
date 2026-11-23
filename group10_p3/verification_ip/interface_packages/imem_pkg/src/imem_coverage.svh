// imem_coverage
// Instruction coverage for the LC3, sampled on every instruction fetch the
// instruction-memory monitor observes (t.data is the word returned to the CPU).
//
// WHY HERE
//   This is the only place every word the stimulus sends is seen, independent of
//   which test or sequence produced it. A replacement model (for example an
//   instructor's) can be plugged in without touching the bench:
//     imem_coverage::type_id::set_type_override(their_coverage::get_type());
//   Because this controller never fetches down a wrong path, fetch order is
//   execution order, so the back-to-back covergroups (dependency_cg, sequence_cg)
//   describe what the pipeline really executed.
//
// COVERGROUPS
//   Instruction-level (from the former decode_in coverage)
//     opcode_cg        each of the 12 implemented opcodes
//     alu_mode_cg      ADD/AND x register/immediate
//     destination_cg   writer opcode x DR
//     source1_cg       SR1/BaseR reader opcode x SR1
//     source2_cg       SR2/SR reader opcode x SR2
//     branch_cg        all 8 BR conditions (000 = never taken)
//     offset_cg        PC/base offset opcode x offset sign
//     dependency_cg    ALU/load producer -> next instruction reads it via SR1/SR2
//   Exhaustive encoding crosses (every legal word of each format, 37448 bins total)
//     alu_imm_cg       ADD/AND x DR x SR1 x imm5        4096
//     alu_reg_cg       ADD/AND x DR x SR1 x SR2         1024
//     not_cg           DR x SR                            64
//     ld_ldi_lea_cg    LD/LDI/LEA x DR x PCoffset9     12288
//     ldr_cg           DR x BaseR x offset6             4096
//     st_sti_cg        ST/STI x SR x PCoffset9          8192
//     str_cg           SR x BaseR x offset6             4096
//     br_cg            nzp (001..111) x PCoffset9       3584
//     jmp_cg           BaseR                               8
//   Field values and ordering
//     field_value_cg   opcode x magnitude class of imm5 / offset6 / PCoffset9
//     sequence_cg      opcode x previous opcode (144)
class imem_coverage extends uvm_subscriber #(imem_transaction);
  `uvm_component_utils(imem_coverage)

  typedef enum bit [3:0] {
    OP_BR  = 4'b0000,
    OP_ADD = 4'b0001,
    OP_LD  = 4'b0010,
    OP_ST  = 4'b0011,
    OP_AND = 4'b0101,
    OP_LDR = 4'b0110,
    OP_STR = 4'b0111,
    OP_NOT = 4'b1001,
    OP_LDI = 4'b1010,
    OP_STI = 4'b1011,
    OP_JMP = 4'b1100,
    OP_LEA = 4'b1110
  } opcode_e;

  bit          [3:0] opcode_sample;
  bit                previous_valid;
  bit          [3:0] previous_op;
  bit                previous_writes;
  bit                previous_load;
  bit          [2:0] previous_dr;
  int unsigned       fetches;

  // ---------------------------------------------------------------------------
  // Instruction-level coverage
  // ---------------------------------------------------------------------------
  covergroup opcode_cg;
    option.per_instance = 1;
    opcode_cp: coverpoint opcode_sample {
      bins BR               = {4'b0000};
      bins ADD              = {4'b0001};
      bins LD               = {4'b0010};
      bins ST               = {4'b0011};
      bins AND              = {4'b0101};
      bins LDR              = {4'b0110};
      bins STR              = {4'b0111};
      bins NOT              = {4'b1001};
      bins LDI              = {4'b1010};
      bins STI              = {4'b1011};
      bins JMP              = {4'b1100};
      illegal_bins RESERVED = {4'b1101};
      bins LEA              = {4'b1110};
    }
  endgroup : opcode_cg

  covergroup alu_mode_cg with function sample (bit [3:0] op, bit immediate);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins ADD = {4'b0001};
      bins AND = {4'b0101};
    }
    mode_cp: coverpoint immediate {
      bins register  = {1'b0};
      bins immediate = {1'b1};
    }
    op_x_mode: cross op_cp, mode_cp;
  endgroup : alu_mode_cg

  covergroup destination_cg with function sample (bit [3:0] op, bit [2:0] dr);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins ADD = {4'b0001};
      bins LD  = {4'b0010};
      bins AND = {4'b0101};
      bins LDR = {4'b0110};
      bins NOT = {4'b1001};
      bins LDI = {4'b1010};
      bins LEA = {4'b1110};
    }
    dr_cp: coverpoint dr;
    op_x_dr: cross op_cp, dr_cp;
  endgroup : destination_cg

  covergroup source1_cg with function sample (bit [3:0] op, bit [2:0] sr1);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins ADD = {4'b0001};
      bins AND = {4'b0101};
      bins LDR = {4'b0110};
      bins STR = {4'b0111};
      bins NOT = {4'b1001};
      bins JMP = {4'b1100};
    }
    sr1_cp: coverpoint sr1;
    op_x_sr1: cross op_cp, sr1_cp;
  endgroup : source1_cg

  covergroup source2_cg with function sample (bit [3:0] op, bit [2:0] sr2);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins ADD = {4'b0001};
      bins ST  = {4'b0011};
      bins AND = {4'b0101};
      bins STR = {4'b0111};
      bins STI = {4'b1011};
    }
    sr2_cp: coverpoint sr2;
    op_x_sr2: cross op_cp, sr2_cp;
  endgroup : source2_cg

  covergroup branch_cg with function sample (bit [2:0] nzp);
    option.per_instance = 1;
    nzp_cp: coverpoint nzp {
      bins never = {3'b000};
      bins p     = {3'b001};
      bins z     = {3'b010};
      bins zp    = {3'b011};
      bins n     = {3'b100};
      bins np    = {3'b101};
      bins nz    = {3'b110};
      bins nzp   = {3'b111};
    }
  endgroup : branch_cg

  covergroup offset_cg with function sample (bit [3:0] op, bit negative);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins BR  = {4'b0000};
      bins LD  = {4'b0010};
      bins ST  = {4'b0011};
      bins LDR = {4'b0110};
      bins STR = {4'b0111};
      bins LDI = {4'b1010};
      bins STI = {4'b1011};
      bins LEA = {4'b1110};
    }
    sign_cp: coverpoint negative {
      bins positive = {1'b0};
      bins negative = {1'b1};
    }
    op_x_sign: cross op_cp, sign_cp;
  endgroup : offset_cg

  covergroup dependency_cg with function sample (bit load_producer, bit second_source);
    option.per_instance = 1;
    producer_cp: coverpoint load_producer {
      bins alu  = {1'b0};
      bins load = {1'b1};
    }
    operand_cp: coverpoint second_source {
      bins sr1 = {1'b0};
      bins sr2 = {1'b1};
    }
    producer_x_operand: cross producer_cp, operand_cp;
  endgroup : dependency_cg

  // ---------------------------------------------------------------------------
  // Exhaustive encoding crosses
  // ---------------------------------------------------------------------------
  covergroup alu_imm_cg with function sample (bit [3:0] op, bit [2:0] dr, bit [2:0] sr1, bit [4:0] imm5);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins ADD = {4'b0001};
      bins AND = {4'b0101};
    }
    dr_cp: coverpoint dr;
    sr1_cp: coverpoint sr1;
    imm5_cp: coverpoint imm5 {
      bins v[] = {[0 : 31]};
    }
    op_dr_sr1_imm5: cross op_cp, dr_cp, sr1_cp, imm5_cp;
  endgroup : alu_imm_cg

  covergroup alu_reg_cg with function sample (bit [3:0] op, bit [2:0] dr, bit [2:0] sr1, bit [2:0] sr2);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins ADD = {4'b0001};
      bins AND = {4'b0101};
    }
    dr_cp: coverpoint dr;
    sr1_cp: coverpoint sr1;
    sr2_cp: coverpoint sr2;
    op_dr_sr1_sr2: cross op_cp, dr_cp, sr1_cp, sr2_cp;
  endgroup : alu_reg_cg

  covergroup not_cg with function sample (bit [2:0] dr, bit [2:0] sr);
    option.per_instance = 1;
    dr_cp: coverpoint dr;
    sr_cp: coverpoint sr;
    dr_sr: cross dr_cp, sr_cp;
  endgroup : not_cg

  covergroup ld_ldi_lea_cg with function sample (bit [3:0] op, bit [2:0] dr, bit [8:0] off9);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins LD  = {4'b0010};
      bins LDI = {4'b1010};
      bins LEA = {4'b1110};
    }
    dr_cp: coverpoint dr;
    off9_cp: coverpoint off9 {
      bins v[] = {[0 : 511]};
    }
    op_dr_off9: cross op_cp, dr_cp, off9_cp;
  endgroup : ld_ldi_lea_cg

  covergroup ldr_cg with function sample (bit [2:0] dr, bit [2:0] base, bit [5:0] off6);
    option.per_instance = 1;
    dr_cp: coverpoint dr;
    base_cp: coverpoint base;
    off6_cp: coverpoint off6 {
      bins v[] = {[0 : 63]};
    }
    dr_base_off6: cross dr_cp, base_cp, off6_cp;
  endgroup : ldr_cg

  covergroup st_sti_cg with function sample (bit [3:0] op, bit [2:0] sr, bit [8:0] off9);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins ST  = {4'b0011};
      bins STI = {4'b1011};
    }
    sr_cp: coverpoint sr;
    off9_cp: coverpoint off9 {
      bins v[] = {[0 : 511]};
    }
    op_sr_off9: cross op_cp, sr_cp, off9_cp;
  endgroup : st_sti_cg

  covergroup str_cg with function sample (bit [2:0] sr, bit [2:0] base, bit [5:0] off6);
    option.per_instance = 1;
    sr_cp: coverpoint sr;
    base_cp: coverpoint base;
    off6_cp: coverpoint off6 {
      bins v[] = {[0 : 63]};
    }
    sr_base_off6: cross sr_cp, base_cp, off6_cp;
  endgroup : str_cg

  // nzp = 000 is a never-taken branch; it is counted in branch_cg and excluded here
  // because 0x0000 is a known DUT problem and is never generated.
  covergroup br_cg with function sample (bit [2:0] nzp, bit [8:0] off9);
    option.per_instance = 1;
    nzp_cp: coverpoint nzp {
      bins v[] = {[1 : 7]};
    }
    off9_cp: coverpoint off9 {
      bins v[] = {[0 : 511]};
    }
    nzp_off9: cross nzp_cp, off9_cp;
  endgroup : br_cg

  covergroup jmp_cg with function sample (bit [2:0] base);
    option.per_instance = 1;
    base_cp: coverpoint base;
  endgroup : jmp_cg

  // ---------------------------------------------------------------------------
  // Field magnitude classes and instruction ordering
  // ---------------------------------------------------------------------------
  // Classes follow the most significant bit of the magnitude, so every bit of
  // each field is exercised in both signs, plus the extreme values.
  covergroup field_value_cg with function sample (
      bit [3:0] op, bit imm_mode, bit [4:0] imm5, bit [5:0] off6, bit [8:0] off9
  );
    option.per_instance = 1;
    // Only the opcode x class crosses count; the bare points are building blocks.
    imm_op_cp: coverpoint op {
      option.weight = 0;
      bins ADD = {4'b0001};
      bins AND = {4'b0101};
    }
    off6_op_cp: coverpoint op {
      option.weight = 0;
      bins LDR = {4'b0110};
      bins STR = {4'b0111};
    }
    off9_op_cp: coverpoint op {
      option.weight = 0;
      bins BR  = {4'b0000};
      bins LD  = {4'b0010};
      bins ST  = {4'b0011};
      bins LDI = {4'b1010};
      bins STI = {4'b1011};
      bins LEA = {4'b1110};
    }
    imm5_cp: coverpoint imm5 iff (imm_mode) {
      option.weight = 0;
      bins zero  = {0};
      bins one   = {1};
      bins p2_3  = {[2 : 3]};
      bins p4_7  = {[4 : 7]};
      bins p8_15 = {[8 : 15]};
      bins m1    = {31};
      bins m2_3  = {[29 : 30]};
      bins m4_7  = {[25 : 28]};
      bins m8_15 = {[17 : 24]};
      bins min   = {16};
    }
    off6_cp: coverpoint off6 {
      option.weight = 0;
      bins zero   = {0};
      bins one    = {1};
      bins p2_3   = {[2 : 3]};
      bins p4_7   = {[4 : 7]};
      bins p8_15  = {[8 : 15]};
      bins p16_31 = {[16 : 31]};
      bins m1     = {63};
      bins m2_3   = {[61 : 62]};
      bins m4_7   = {[57 : 60]};
      bins m8_15  = {[49 : 56]};
      bins m16_31 = {[33 : 48]};
      bins min    = {32};
    }
    off9_cp: coverpoint off9 {
      option.weight = 0;
      bins zero     = {0};
      bins one      = {1};
      bins p2_3     = {[2 : 3]};
      bins p4_7     = {[4 : 7]};
      bins p8_15    = {[8 : 15]};
      bins p16_31   = {[16 : 31]};
      bins p32_63   = {[32 : 63]};
      bins p64_127  = {[64 : 127]};
      bins p128_255 = {[128 : 255]};
      bins m1       = {511};
      bins m2_3     = {[509 : 510]};
      bins m4_7     = {[505 : 508]};
      bins m8_15    = {[497 : 504]};
      bins m16_31   = {[481 : 496]};
      bins m32_63   = {[449 : 480]};
      bins m64_127  = {[385 : 448]};
      bins m128_255 = {[257 : 384]};
      bins min      = {256};
    }
    imm5_x_op: cross imm_op_cp, imm5_cp;
    off6_x_op: cross off6_op_cp, off6_cp;
    off9_x_op: cross off9_op_cp, off9_cp;
  endgroup : field_value_cg

  covergroup sequence_cg with function sample (bit [3:0] op, bit [3:0] prev);
    option.per_instance = 1;
    op_cp: coverpoint op {
      bins BR  = {4'b0000};
      bins ADD = {4'b0001};
      bins LD  = {4'b0010};
      bins ST  = {4'b0011};
      bins AND = {4'b0101};
      bins LDR = {4'b0110};
      bins STR = {4'b0111};
      bins NOT = {4'b1001};
      bins LDI = {4'b1010};
      bins STI = {4'b1011};
      bins JMP = {4'b1100};
      bins LEA = {4'b1110};
    }
    prev_cp: coverpoint prev {
      bins BR  = {4'b0000};
      bins ADD = {4'b0001};
      bins LD  = {4'b0010};
      bins ST  = {4'b0011};
      bins AND = {4'b0101};
      bins LDR = {4'b0110};
      bins STR = {4'b0111};
      bins NOT = {4'b1001};
      bins LDI = {4'b1010};
      bins STI = {4'b1011};
      bins JMP = {4'b1100};
      bins LEA = {4'b1110};
    }
    prev_x_op: cross prev_cp, op_cp;
  endgroup : sequence_cg

  function new(string name, uvm_component parent);
    super.new(name, parent);
    opcode_cg      = new();
    alu_mode_cg    = new();
    destination_cg = new();
    source1_cg     = new();
    source2_cg     = new();
    branch_cg      = new();
    offset_cg      = new();
    dependency_cg  = new();
    alu_imm_cg     = new();
    alu_reg_cg     = new();
    not_cg         = new();
    ld_ldi_lea_cg  = new();
    ldr_cg         = new();
    st_sti_cg      = new();
    str_cg         = new();
    br_cg          = new();
    jmp_cg         = new();
    field_value_cg = new();
    sequence_cg    = new();
  endfunction

  virtual function void write(imem_transaction t);
    bit [15:0] insn;
    bit [ 3:0] op;
    bit reads_sr1, reads_sr2;
    bit [2:0] dr, sr1, sr2;
    insn = t.data;
    op   = insn[15:12];
    dr   = insn[11:9];
    sr1  = insn[8:6];
    fetches++;

    opcode_sample = op;
    opcode_cg.sample();

    reads_sr1 = op inside {OP_ADD, OP_AND, OP_LDR, OP_STR, OP_NOT, OP_JMP};
    reads_sr2 = (op inside {OP_ADD, OP_AND} && !insn[5]) || op inside {OP_ST, OP_STR, OP_STI};
    sr2       = op inside {OP_ADD, OP_AND} ? insn[2:0] : insn[11:9];

    // instruction-level
    if (op inside {OP_ADD, OP_AND}) alu_mode_cg.sample(op, insn[5]);
    if (op inside {OP_ADD, OP_LD, OP_AND, OP_LDR, OP_NOT, OP_LDI, OP_LEA}) destination_cg.sample(op, dr);
    if (reads_sr1) source1_cg.sample(op, sr1);
    if (reads_sr2) source2_cg.sample(op, sr2);
    if (op == OP_BR) branch_cg.sample(insn[11:9]);
    if (op inside {OP_BR, OP_LD, OP_ST, OP_LDI, OP_STI, OP_LEA}) offset_cg.sample(op, insn[8]);
    if (op inside {OP_LDR, OP_STR}) offset_cg.sample(op, insn[5]);
    if (previous_writes && reads_sr1 && sr1 == previous_dr) dependency_cg.sample(previous_load, 1'b0);
    if (previous_writes && reads_sr2 && sr2 == previous_dr) dependency_cg.sample(previous_load, 1'b1);

    // exhaustive encodings
    case (op)
      OP_ADD, OP_AND:
      if (insn[5]) alu_imm_cg.sample(op, dr, sr1, insn[4:0]);
      else alu_reg_cg.sample(op, dr, sr1, insn[2:0]);
      OP_NOT: not_cg.sample(dr, sr1);
      OP_LD, OP_LDI, OP_LEA: ld_ldi_lea_cg.sample(op, dr, insn[8:0]);
      OP_LDR: ldr_cg.sample(dr, sr1, insn[5:0]);
      OP_ST, OP_STI: st_sti_cg.sample(op, dr, insn[8:0]);
      OP_STR: str_cg.sample(dr, sr1, insn[5:0]);
      OP_BR: br_cg.sample(insn[11:9], insn[8:0]);
      OP_JMP: jmp_cg.sample(sr1);
      default: ;
    endcase

    // field values and ordering
    field_value_cg.sample(op, insn[5], insn[4:0], insn[5:0], insn[8:0]);
    if (previous_valid) sequence_cg.sample(op, previous_op);

    previous_valid  = 1;
    previous_op     = op;
    previous_writes = op inside {OP_ADD, OP_LD, OP_AND, OP_LDR, OP_NOT, OP_LDI, OP_LEA};
    previous_load   = op inside {OP_LD, OP_LDR, OP_LDI};
    previous_dr     = dr;
  endfunction

  // Average of all covergroups, each weighted equally.
  function real instruction_coverage();
    real total;
    total = opcode_cg.get_inst_coverage()      + alu_mode_cg.get_inst_coverage()   +
            destination_cg.get_inst_coverage() + source1_cg.get_inst_coverage()    +
            source2_cg.get_inst_coverage()     + branch_cg.get_inst_coverage()     +
            offset_cg.get_inst_coverage()      + dependency_cg.get_inst_coverage() +
            alu_imm_cg.get_inst_coverage()     + alu_reg_cg.get_inst_coverage()    +
            not_cg.get_inst_coverage()         + ld_ldi_lea_cg.get_inst_coverage() +
            ldr_cg.get_inst_coverage()         + st_sti_cg.get_inst_coverage()     +
            str_cg.get_inst_coverage()         + br_cg.get_inst_coverage()         +
            jmp_cg.get_inst_coverage()         + field_value_cg.get_inst_coverage() +
            sequence_cg.get_inst_coverage();
    return total / 19.0;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    string s;
    s = $sformatf("instruction coverage over %0d fetches: %6.2f%%\n", fetches, instruction_coverage());
    s = {
      s,
      $sformatf(
          "  opcode_cg      %6.2f%%   alu_mode_cg    %6.2f%%   destination_cg %6.2f%%\n",
          opcode_cg.get_inst_coverage(),
          alu_mode_cg.get_inst_coverage(),
          destination_cg.get_inst_coverage()
      )
    };
    s = {
      s,
      $sformatf(
          "  source1_cg     %6.2f%%   source2_cg     %6.2f%%   branch_cg      %6.2f%%\n",
          source1_cg.get_inst_coverage(),
          source2_cg.get_inst_coverage(),
          branch_cg.get_inst_coverage()
      )
    };
    s = {
      s,
      $sformatf(
          "  offset_cg      %6.2f%%   dependency_cg  %6.2f%%   sequence_cg    %6.2f%%\n",
          offset_cg.get_inst_coverage(),
          dependency_cg.get_inst_coverage(),
          sequence_cg.get_inst_coverage()
      )
    };
    s = {
      s,
      $sformatf(
          "  field_value_cg %6.2f%%   jmp_cg         %6.2f%%   not_cg         %6.2f%%\n",
          field_value_cg.get_inst_coverage(),
          jmp_cg.get_inst_coverage(),
          not_cg.get_inst_coverage()
      )
    };
    s = {
      s,
      $sformatf(
          "  alu_imm_cg     %6.2f%%   alu_reg_cg     %6.2f%%   ld_ldi_lea_cg  %6.2f%%\n",
          alu_imm_cg.get_inst_coverage(),
          alu_reg_cg.get_inst_coverage(),
          ld_ldi_lea_cg.get_inst_coverage()
      )
    };
    s = {
      s,
      $sformatf(
          "  ldr_cg         %6.2f%%   st_sti_cg      %6.2f%%   str_cg         %6.2f%%\n",
          ldr_cg.get_inst_coverage(),
          st_sti_cg.get_inst_coverage(),
          str_cg.get_inst_coverage()
      )
    };
    s = {s, $sformatf("  br_cg          %6.2f%%", br_cg.get_inst_coverage())};
    `uvm_info("IMEM_COVERAGE", s, UVM_LOW);
  endfunction
endclass : imem_coverage
