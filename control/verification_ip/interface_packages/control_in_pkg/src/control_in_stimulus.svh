// control_in_stimulus
// Sequence item for the ACTIVE control_in agent (block-level bench only).
//
// Why a separate class from control_in_transaction:
//   control_in_transaction is what the MONITOR sees - one clock cycle of all seven
//   controller inputs. What a test wants to CONTROL is different: the instruction
//   stream and the memory timing. IR, IR_Exec, NZP and psr are not free stimulus;
//   in the LC3 they are produced by Decode/Execute/Writeback in response to the
//   controller's own enables, and control_in_driver_bfm reproduces that. Keeping the
//   two classes separate keeps "what we drive" and "what we observed" unambiguous.
//
// One item = one instruction as instruction memory delivers it, plus the timing the
// memories apply while it flows through the pipeline.
typedef enum {
  MIX_RANDOM,   // any legal instruction, uniform opcodes
  MIX_HAZARD,   // ALU/load heavy, registers R0-R1 only -> lots of RAW hazards / bypasses
  MIX_MEMORY,   // loads/stores (incl. LDI/STI) with data-memory wait states
  MIX_BRANCH    // BR/JMP mixed with ALU ops that set psr -> taken and not taken
} control_mix_e;

class control_in_stimulus extends uvm_sequence_item;
  `uvm_object_utils(control_in_stimulus)

  // Instruction delivered on Instr_dout.
  rand bit [3:0]    opcode;
  rand bit [11:0]   operand;
  rand bit [15:0]   instr;

  // Instruction-memory latency: cycles complete_instr stays low after this
  // instruction's address is presented.
  rand int unsigned instr_wait;
  // Data-memory latency used for memory accesses while this item is current:
  // cycles complete_data stays low in each memory state.
  rand int unsigned data_wait;
  // Value Writeback reports on psr at the next register-file write.
  rand bit [2:0]    wb_psr;

  // Not random: the sequence picks the instruction mix before randomize().
  control_mix_e     mix = MIX_RANDOM;

  // Instruction-memory wait states are OFF by default.
  // The spec says enable_updatePC must stay low while complete_instr is low, but
  // lc3_prediction_pkg::controller_model() never gates enable_updatePC with
  // complete_instr (it only marks the fetched word invalid). With waits on, the
  // predictor and a spec-correct controller disagree by construction, so those
  // mismatches would say nothing about RTL bugs. Turn on only to study that case.
  bit               allow_instr_wait = 0;

  int  transaction_view_h;
  time start_time, end_time;

  constraint instr_c {
    instr == {opcode, operand};
    solve opcode before operand;
  }

  // The 12 opcodes this LC3 implements (same set as decode_in in P2).
  // RESERVED (1101) is excluded on purpose: lc3_prediction_pkg::decode_lc3_insn()
  // asserts on it, and the controller model decodes Instr_dout every cycle.
  constraint legal_opcode_c {
    opcode inside {4'b0000, 4'b0001, 4'b0010, 4'b0011, 4'b0101, 4'b0110,
                   4'b0111, 4'b1001, 4'b1010, 4'b1011, 4'b1100, 4'b1110};
  }

  constraint legal_encoding_c {
    (opcode == 4'b1001) -> (operand[5:0] == 6'b111111);                          // NOT
    (opcode == 4'b1100) -> (operand[11:9] == 3'b000 && operand[5:0] == 6'b000000); // JMP
    ((opcode inside {4'b0001, 4'b0101}) && operand[5] == 1'b0) -> (operand[4:3] == 2'b00);
  }

  // Branch conditions: mostly real conditions; BR with nzp=000 (never taken) is rare.
  constraint br_cond_c {
    (opcode == 4'b0000) -> operand[11:9] dist {3'b000 := 1, [3'b001:3'b111] :/ 20};
  }

  constraint psr_c { wb_psr inside {3'b100, 3'b010, 3'b001}; }

  // Upper bounds match the [*1:8] repetition bins in control_out_coverage.
  constraint wait_c {
    !allow_instr_wait -> instr_wait == 0;
    instr_wait dist {0 :/ 75, [1:3] :/ 20, [4:8] :/ 5};
    data_wait  dist {0 :/ 60, [1:3] :/ 30, [4:8] :/ 10};
  }

  constraint mix_c {
    (mix == MIX_HAZARD) -> {
      opcode dist {4'b0001 := 4, 4'b0101 := 3, 4'b1001 := 2, 4'b1110 := 1,  // ADD AND NOT LEA
                   4'b0010 := 1, 4'b0110 := 1, 4'b1010 := 1,                // LD LDR LDI
                   4'b0011 := 1, 4'b0111 := 1};                             // ST STR
      // Squeeze every register field into R0/R1 so consecutive instructions collide.
      (opcode != 4'b0000) -> operand[11:10] == 2'b00;
      operand[8:7] == 2'b00;
      ((opcode inside {4'b0001, 4'b0101}) && operand[5] == 1'b0) -> operand[2:1] == 2'b00;
    }
    (mix == MIX_MEMORY) -> {
      opcode dist {4'b0010 := 2, 4'b0110 := 2, 4'b1010 := 2,                // LD LDR LDI
                   4'b0011 := 2, 4'b0111 := 2, 4'b1011 := 2,                // ST STR STI
                   4'b0001 := 1, 4'b0101 := 1};                             // ALU in between
      data_wait dist {0 :/ 30, [1:3] :/ 50, [4:8] :/ 20};
    }
    (mix == MIX_BRANCH) -> {
      opcode dist {4'b0000 := 4, 4'b1100 := 1,                              // BR JMP
                   4'b0001 := 2, 4'b0101 := 2, 4'b1001 := 1};               // set psr
    }
  }

  function new(string name = "control_in_stimulus");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("instr=0x%4h (opcode=4'b%4b) instr_wait=%0d data_wait=%0d wb_psr=3'b%3b mix=%s",
                     instr, instr[15:12], instr_wait, data_wait, wb_psr, mix.name());
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("instr",      instr,      16, UVM_HEX);
    printer.print_field("instr_wait", instr_wait, 32, UVM_DEC);
    printer.print_field("data_wait",  data_wait,  32, UVM_DEC);
    printer.print_field("wb_psr",     wb_psr,     3,  UVM_BIN);
    printer.print_string("mix",       mix.name());
  endfunction

  virtual function void do_copy(uvm_object rhs);
    control_in_stimulus rhs_;
    if (!$cast(rhs_, rhs)) `uvm_fatal("CAST", "do_copy: argument is not a control_in_stimulus")
    super.do_copy(rhs);
    opcode     = rhs_.opcode;
    operand    = rhs_.operand;
    instr      = rhs_.instr;
    instr_wait = rhs_.instr_wait;
    data_wait  = rhs_.data_wait;
    wb_psr     = rhs_.wb_psr;
    mix        = rhs_.mix;
    allow_instr_wait = rhs_.allow_instr_wait;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    control_in_stimulus rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return super.do_compare(rhs, comparer) && instr == rhs_.instr &&
           instr_wait == rhs_.instr_wait && data_wait == rhs_.data_wait && wb_psr == rhs_.wb_psr;
  endfunction
endclass : control_in_stimulus
