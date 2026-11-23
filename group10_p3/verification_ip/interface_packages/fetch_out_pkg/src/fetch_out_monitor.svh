class fetch_out_monitor extends uvm_monitor;
  `uvm_component_utils(fetch_out_monitor)
  fetch_out_configuration                    configuration;
  uvm_analysis_port #(fetch_out_transaction) monitored_ap;
  longint unsigned                           count;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    monitored_ap = new("monitored_ap", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    if (configuration == null || configuration.monitor_bfm == null) `uvm_fatal("CFG", "fetch BFM missing");
    configuration.monitor_bfm.proxy = this;
  endfunction
  task run_phase(uvm_phase phase);
    configuration.monitor_bfm.start_monitoring();
  endtask
  function void notify_transaction(input logic reset, input logic [15:0] pc, input logic [15:0] npc,
                                   input logic instrmem_rd);
    fetch_out_transaction t;
    t             = fetch_out_transaction::type_id::create("t");
    t.reset       = reset;
    t.pc          = pc;
    t.npc         = npc;
    t.instrmem_rd = instrmem_rd;
    t.cycle       = count++;
    monitored_ap.write(t);
  endfunction
endclass
