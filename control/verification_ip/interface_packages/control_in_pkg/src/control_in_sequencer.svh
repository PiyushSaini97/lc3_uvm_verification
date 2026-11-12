// control_in_sequencer
// Used only when the agent is ACTIVE (control block bench). Its items are
// control_in_stimulus (instructions + memory timing), not the per-cycle
// control_in_transaction the monitor produces.
class control_in_sequencer extends uvm_sequencer #(control_in_stimulus);
  `uvm_component_utils(control_in_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : control_in_sequencer
