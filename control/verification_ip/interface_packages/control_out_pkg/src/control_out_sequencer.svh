// control_out_sequencer
// Never instantiated (passive agent); kept for package-structure parity with P2.
class control_out_sequencer extends uvm_sequencer #(control_out_transaction);
  `uvm_component_utils(control_out_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : control_out_sequencer
