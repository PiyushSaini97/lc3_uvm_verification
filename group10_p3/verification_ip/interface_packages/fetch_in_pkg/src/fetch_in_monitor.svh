class fetch_in_monitor extends uvm_monitor;
  `uvm_component_utils(fetch_in_monitor)
  fetch_in_configuration                    configuration;
  uvm_analysis_port #(fetch_in_transaction) monitored_ap;
  longint unsigned                          count;
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
  function void notify_transaction(input logic reset, input logic enable_updatePC, input logic enable_fetch,
                                   input logic br_taken, input logic [15:0] taddr);
    fetch_in_transaction t;
    t                 = fetch_in_transaction::type_id::create("t");
    t.reset           = reset;
    t.enable_updatePC = enable_updatePC;
    t.enable_fetch    = enable_fetch;
    t.br_taken        = br_taken;
    t.taddr           = taddr;
    t.cycle           = count++;
    monitored_ap.write(t);
  endfunction
endclass
