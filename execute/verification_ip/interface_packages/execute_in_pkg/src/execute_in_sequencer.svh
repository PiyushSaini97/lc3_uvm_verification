// execute_in_sequencer
// Used only when the agent is ACTIVE (execute block bench).
class execute_in_sequencer extends uvm_sequencer #(execute_in_transaction);
  `uvm_component_utils(execute_in_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : execute_in_sequencer
