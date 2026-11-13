// memaccess_in_sequencer
// Used only when the agent is ACTIVE (memaccess block bench). Its items are
// memaccess_in_stimulus (one cycle of input values), not the
// memaccess_in_transaction the monitor produces.
class memaccess_in_sequencer extends uvm_sequencer #(memaccess_in_stimulus);
  `uvm_component_utils(memaccess_in_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : memaccess_in_sequencer
