class decode_in_coverage extends uvm_subscriber #(decode_in_transaction);
  `uvm_component_utils(decode_in_coverage)

  bit [3:0] opcode_sample;

  covergroup opcode_cg;
    option.per_instance = 1;
    opcode_cp : coverpoint opcode_sample {
      bins BR   = {4'b0000};
      bins ADD  = {4'b0001};
      bins LD   = {4'b0010};
      bins ST   = {4'b0011};
      ignore_bins JSR = {4'b0100};
      bins AND  = {4'b0101};
      bins LDR  = {4'b0110};
      bins STR  = {4'b0111};
      ignore_bins RTI = {4'b1000};
      bins NOT  = {4'b1001};
      bins LDI  = {4'b1010};
      bins STI  = {4'b1011};
      bins JMP  = {4'b1100};
      illegal_bins RESERVED = {4'b1101};
      bins LEA  = {4'b1110};
      ignore_bins TRAP = {4'b1111};
    }
  endgroup : opcode_cg

  function new(string name, uvm_component parent);
    super.new(name, parent);
    opcode_cg = new();
  endfunction

  virtual function void write(decode_in_transaction t);
    opcode_sample = t.dout[15:12];
    opcode_cg.sample();
  endfunction
endclass : decode_in_coverage
