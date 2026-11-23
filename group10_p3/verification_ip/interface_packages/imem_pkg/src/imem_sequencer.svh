class imem_sequencer extends uvm_sequencer #(imem_transaction);
  `uvm_component_utils(imem_sequencer)
  uvm_tlm_fifo #(imem_transaction) requests;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    requests = new("requests", this, 1);
  endfunction
endclass
