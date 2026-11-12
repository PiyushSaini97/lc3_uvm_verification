// control_in_coverage
// Functional coverage of the conditions the controller has to react to. These are
// the stimulus-side goals for the P3 test plan: if a bin is empty, the tests never
// exercised that controller path.
class control_in_coverage extends uvm_subscriber #(control_in_transaction);
  `uvm_component_utils(control_in_coverage)

  control_in_transaction t_s;

  covergroup control_in_cg;
    option.per_instance = 1;

    // Memory wait states: complete_* low means the memory stretched the access.
    complete_instr_cp : coverpoint t_s.complete_instr {
      bins ready = {1'b1};
      bins wait_ = {1'b0};
    }
    complete_data_cp : coverpoint t_s.complete_data {
      bins ready = {1'b1};
      bins wait_ = {1'b0};
    }

    // Result of the most recent register-file write.
    psr_cp : coverpoint t_s.psr {
      bins N = {3'b100};
      bins Z = {3'b010};
      bins P = {3'b001};
    }

    // Branch condition presented by Execute (000 = not a control instruction).
    nzp_cp : coverpoint t_s.NZP {
      bins none  = {3'b000};
      bins brp   = {3'b001};
      bins brz   = {3'b010};
      bins brzp  = {3'b011};
      bins brn   = {3'b100};
      bins brnp  = {3'b101};
      bins brnz  = {3'b110};
      bins brnzp = {3'b111};
    }

    // Every branch condition against every psr value -> both taken and not taken.
    branch_decision_cx : cross nzp_cp, psr_cp {
      ignore_bins no_branch = binsof(nzp_cp.none);
    }

    // Memory instructions reaching Execute output (these trigger mem_state FSM).
    exec_mem_op_cp : coverpoint t_s.IR_Exec[15:12] {
      bins LD  = {4'b0010};
      bins LDR = {4'b0110};
      bins LDI = {4'b1010};
      bins ST  = {4'b0011};
      bins STR = {4'b0111};
      bins STI = {4'b1011};
    }

    // Memory access that has to wait on complete_data.
    mem_wait_cx : cross exec_mem_op_cp, complete_data_cp;
  endgroup : control_in_cg

  function new(string name, uvm_component parent);
    super.new(name, parent);
    control_in_cg = new();
  endfunction

  virtual function void write(control_in_transaction t);
    if (t.prime) return;   // reset-cycle priming sample: not real operation
    t_s = t;
    control_in_cg.sample();
  endfunction
endclass : control_in_coverage
