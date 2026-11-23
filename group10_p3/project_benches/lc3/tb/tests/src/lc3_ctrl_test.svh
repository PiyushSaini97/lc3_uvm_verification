// lc3_ctrl_test
// BR-heavy with JMP and condition-code setters: branch taken/not taken under N, Z and P, control stalls.
// Stimulus: imem_responder_sequence randomizing imem_ctrl_transaction.
class lc3_ctrl_test extends lc3_base_test;
  `uvm_component_utils(lc3_ctrl_test)
  function new(string name = "lc3_ctrl_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  protected virtual function void set_overrides();
    imem_transaction::type_id::set_type_override(imem_ctrl_transaction::get_type());
  endfunction
  // BR/JMP/ADD/AND/NOT only: no loads or stores, so no data-memory traffic to require.
  protected virtual function int unsigned min_dmem_checks();
    return 0;
  endfunction
endclass : lc3_ctrl_test
