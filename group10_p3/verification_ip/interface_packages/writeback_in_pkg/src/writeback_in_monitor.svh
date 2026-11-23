class writeback_in_monitor extends uvm_monitor;
  `uvm_component_utils(writeback_in_monitor)
  writeback_in_configuration                    configuration;
  uvm_analysis_port #(writeback_in_transaction) monitored_ap;

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

  virtual function void notify_transaction(
      input longint unsigned cycle_id, input time sample_time, input logic reset,
      input logic enable_writeback, input logic [1:0] W_Control, input logic [15:0] aluout,
      input logic [15:0] npc, input logic [15:0] pcout, input logic [15:0] memout, input logic [2:0] sr1,
      input logic [2:0] sr2, input logic [2:0] dr);
    writeback_in_transaction t;
    t                  = writeback_in_transaction::type_id::create("observed");
    t.cycle_id         = cycle_id;
    t.sample_time      = sample_time;
    t.reset            = reset;
    t.enable_writeback = enable_writeback;
    t.W_Control        = W_Control;
    t.aluout           = aluout;
    t.npc              = npc;
    t.pcout            = pcout;
    t.memout           = memout;
    t.sr1              = sr1;
    t.sr2              = sr2;
    t.dr               = dr;
    monitored_ap.write(t);
  endfunction
endclass
