// imem_alu_transaction
// Operate instructions only: ADD and AND (both modes) and NOT. Every other
// constraint of imem_transaction (legal encodings, no 0x0000) still applies.
// lc3_alu_test: imem_transaction::type_id::set_type_override(imem_alu_transaction::get_type());
class imem_alu_transaction extends imem_transaction;
  `uvm_object_utils(imem_alu_transaction)
  constraint alu_only_c {opcode inside {4'b0001, 4'b0101, 4'b1001};}
  function new(string name = "imem_alu_transaction");
    super.new(name);
  endfunction
endclass : imem_alu_transaction
