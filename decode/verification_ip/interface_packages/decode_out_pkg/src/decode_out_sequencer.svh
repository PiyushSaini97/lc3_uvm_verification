class decode_out_sequencer extends uvm_sequencer #(decode_out_transaction);
  `uvm_component_utils(decode_out_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass : decode_out_sequencer
