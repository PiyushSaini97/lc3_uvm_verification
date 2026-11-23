class writeback_out_monitor extends uvm_monitor;
  `uvm_component_utils(writeback_out_monitor)
  writeback_out_configuration                    configuration;
  uvm_analysis_port #(writeback_out_transaction) monitored_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    monitored_ap = new("monitored_ap", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (configuration == null) `uvm_fatal("WB_CFG", "Missing monitor configuration");
    if (configuration.monitor_bfm == null) `uvm_fatal("WB_BFM", "Missing monitor BFM");
    configuration.monitor_bfm.proxy = this;
  endfunction

  virtual task run_phase(uvm_phase phase);
    configuration.monitor_bfm.start_monitoring();
  endtask

  virtual function void notify_transaction(input longint unsigned cycle_id, input time sample_time,
                                           input logic reset, input logic [15:0] vsr1,
                                           input logic [15:0] vsr2, input logic [2:0] psr);
    writeback_out_transaction t;
    t             = writeback_out_transaction::type_id::create("observed");
    t.cycle_id    = cycle_id;
    t.sample_time = sample_time;
    t.reset       = reset;
    t.vsr1        = vsr1;
    t.vsr2        = vsr2;
    t.psr         = psr;
    monitored_ap.write(t);
  endfunction
endclass
