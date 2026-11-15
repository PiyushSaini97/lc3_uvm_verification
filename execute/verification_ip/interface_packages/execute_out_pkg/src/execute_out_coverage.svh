// execute_out_coverage
// Observed Execute outputs: control pass-through, condition codes, destination and
// source register numbers, and ALU result corner values.
class execute_out_coverage extends uvm_subscriber #(execute_out_transaction);
  `uvm_component_utils(execute_out_coverage)

  execute_out_transaction t;

  covergroup execute_out_cg;
    option.per_instance = 1;
    //nzp_cp : coverpoint t.nzp { bins n = {3'b100}; bins z = {3'b010}; bins p = {3'b001}; }
    nzp_cp : coverpoint t.nzp {
      bins none = {3'b000};  bins n  = {3'b100};  bins z  = {3'b010};  bins p   = {3'b001};
      bins nz   = {3'b110};  bins np = {3'b101};  bins zp = {3'b011};  bins nzp = {3'b111};
    }
    br_cond_cp : coverpoint t.ir_exec[11:9] iff (t.ir_exec[15:12] == 4'b0000) {
      bins cond[] = {[0:7]};
    }
    w_control_cp : coverpoint t.w_control_out { bins wb_alu = {0}; bins wb_mem = {1}; bins wb_pc = {2}; }
    mem_control_cp : coverpoint t.mem_control_out;
    dr_cp  : coverpoint t.dr  { bins reg_[] = {[0:7]}; }
    sr1_cp : coverpoint t.sr1 { bins reg_[] = {[0:7]}; }
    sr2_cp : coverpoint t.sr2 { bins reg_[] = {[0:7]}; }
    aluout_cp : coverpoint t.aluout {
      bins zero = {16'h0000};  bins one = {16'h0001};
      bins max_pos = {16'h7fff};  bins min_neg = {16'h8000};  bins all_ones = {16'hffff};
    }
    pcout_cp : coverpoint t.pcout {
      bins zero = {16'h0000};  bins all_ones = {16'hffff};
    }
    opcode_cp : coverpoint t.ir_exec[15:12] {
      bins ADD = {4'b0001};  bins AND = {4'b0101};  bins NOT = {4'b1001};
      bins BR  = {4'b0000};  bins JMP = {4'b1100};
      bins LD  = {4'b0010};  bins LDR = {4'b0110};  bins LDI = {4'b1010};  bins LEA = {4'b1110};
      bins ST  = {4'b0011};  bins STR = {4'b0111};  bins STI = {4'b1011};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    execute_out_cg = new();
  endfunction

  virtual function void write(execute_out_transaction t);
    this.t = t;
    execute_out_cg.sample();
  endfunction
endclass : execute_out_coverage
