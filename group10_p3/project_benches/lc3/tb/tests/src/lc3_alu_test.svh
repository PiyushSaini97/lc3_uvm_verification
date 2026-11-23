// lc3_alu_test
// ADD, AND (both modes) and NOT only: ALU results, bypassing between operate instructions, psr updates.
// Stimulus: imem_responder_sequence randomizing imem_alu_transaction.
class lc3_alu_test extends lc3_base_test;
  `uvm_component_utils(lc3_alu_test)
  function new(string name = "lc3_alu_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  protected virtual function void set_overrides();
    imem_transaction::type_id::set_type_override(imem_alu_transaction::get_type());
  endfunction
  // ADD/AND/NOT only: no loads or stores, so no data-memory traffic to require.
  protected virtual function int unsigned min_dmem_checks();
    return 0;
  endfunction
endclass : lc3_alu_test
