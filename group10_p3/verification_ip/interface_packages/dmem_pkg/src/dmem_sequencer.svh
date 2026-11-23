class dmem_sequencer extends uvm_sequencer #(dmem_transaction);
  `uvm_component_utils(dmem_sequencer)
  uvm_tlm_fifo #(dmem_transaction) requests;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    requests = new("requests", this, 1);
  endfunction
endclass
