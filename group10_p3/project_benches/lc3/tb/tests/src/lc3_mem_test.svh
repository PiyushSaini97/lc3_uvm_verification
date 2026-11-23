// lc3_mem_test
// LD, LDI, LEA, LDR, ST, STI, STR only: memory state machine, data-memory stalls, load-use bypassing.
// Stimulus: imem_responder_sequence randomizing imem_mem_transaction.
class lc3_mem_test extends lc3_base_test;
  `uvm_component_utils(lc3_mem_test)
  function new(string name = "lc3_mem_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  protected virtual function void set_overrides();
    imem_transaction::type_id::set_type_override(imem_mem_transaction::get_type());
  endfunction
endclass : lc3_mem_test
