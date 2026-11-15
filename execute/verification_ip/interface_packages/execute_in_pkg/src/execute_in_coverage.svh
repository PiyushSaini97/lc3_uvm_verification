// execute_in_coverage
// Coverage aimed at what the Execute stage has to get right: every opcode, every bypass
// path for every operand the instruction uses, and operand corner values.
// An empty bin means the tests never exercised that path.
class execute_in_coverage extends uvm_subscriber #(execute_in_transaction);
  `uvm_component_utils(execute_in_coverage)

  execute_in_transaction t;
  bit op1_used, op2_used;

  covergroup execute_in_cg;
    option.per_instance = 1;

    opcode_cp : coverpoint t.ir[15:12] {
      bins ADD = {4'b0001};  bins AND = {4'b0101};  bins NOT = {4'b1001};
      bins BR  = {4'b0000};  bins JMP = {4'b1100};
      bins LD  = {4'b0010};  bins LDR = {4'b0110};  bins LDI = {4'b1010};  bins LEA = {4'b1110};
      bins ST  = {4'b0011};  bins STR = {4'b0111};  bins STI = {4'b1011};
    }

    // bypass source for operand 1 and 2: none, alu, mem (both at once is illegal)
    op1_bypass_cp : coverpoint {t.bypass_mem_1, t.bypass_alu_1} iff (op1_used) {
      bins none = {2'b00};  bins alu = {2'b01};  bins mem = {2'b10};
      illegal_bins both = {2'b11};
    }
    op2_bypass_cp : coverpoint {t.bypass_mem_2, t.bypass_alu_2} iff (op2_used) {
      bins none = {2'b00};  bins alu = {2'b01};  bins mem = {2'b10};
      illegal_bins both = {2'b11};
    }

    // only the opcodes that use the operand take part in the cross
    op1_opcode_cp : coverpoint t.ir[15:12] iff (op1_used) {
      bins used[] = {4'b0001, 4'b0101, 4'b1001, 4'b0110, 4'b0111, 4'b1100};
    }
    op2_opcode_cp : coverpoint t.ir[15:12] iff (op2_used) {
      bins used[] = {4'b0001, 4'b0101, 4'b0011, 4'b0111, 4'b1011};
    }
    op1_cross : cross op1_opcode_cp, op1_bypass_cp;
    op2_cross : cross op2_opcode_cp, op2_bypass_cp;

    vsr1_cp : coverpoint t.vsr1 {
      bins zero = {16'h0000};  bins one = {16'h0001};
      bins max_pos = {16'h7fff};  bins min_neg = {16'h8000};  bins all_ones = {16'hffff};
    }
    vsr2_cp : coverpoint t.vsr2 {
      bins zero = {16'h0000};  bins one = {16'h0001};
      bins max_pos = {16'h7fff};  bins min_neg = {16'h8000};  bins all_ones = {16'hffff};
    }
    npc_cp : coverpoint t.npc_in {
      bins zero = {16'h0000};  bins all_ones = {16'hffff};  bins msb_set = {16'h8000};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    execute_in_cg = new();
  endfunction

  virtual function void write(execute_in_transaction t);
    this.t = t;
    op1_used = (t.ir[15:12] inside {4'b0001, 4'b0101, 4'b1001, 4'b0110, 4'b0111, 4'b1100});
    op2_used = ((t.ir[15:12] inside {4'b0001, 4'b0101}) && !t.ir[5]) ||
               (t.ir[15:12] inside {4'b0011, 4'b0111, 4'b1011});
    execute_in_cg.sample();
  endfunction
endclass : execute_in_coverage
