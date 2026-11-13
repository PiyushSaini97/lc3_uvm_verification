// memaccess_out_sequencer
// Declared for symmetry with the other interface packages and because
// memaccess_out_configuration carries a handle to one. The agent is always passive,
// so it is never built.
class memaccess_out_sequencer extends uvm_sequencer #(memaccess_out_transaction);
  `uvm_component_utils(memaccess_out_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : memaccess_out_sequencer
