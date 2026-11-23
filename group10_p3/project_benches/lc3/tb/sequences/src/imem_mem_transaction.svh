// imem_mem_transaction
// Memory instructions only: LD, LDI, LEA, LDR, ST, STI, STR. Back-to-back memory
// operations stress the memory-stage state machine, data-memory stalls and
// load-use bypassing.
// lc3_mem_test: imem_transaction::type_id::set_type_override(imem_mem_transaction::get_type());
class imem_mem_transaction extends imem_transaction;
  `uvm_object_utils(imem_mem_transaction)
  constraint mem_only_c {opcode inside {4'b0010, 4'b0011, 4'b0110, 4'b0111, 4'b1010, 4'b1011, 4'b1110};}
  function new(string name = "imem_mem_transaction");
    super.new(name);
  endfunction
endclass : imem_mem_transaction
