class writeback_out_agent extends uvm_agent;
  `uvm_component_utils(writeback_out_agent)
  writeback_out_configuration                    configuration;
  writeback_out_monitor                          monitor;
  uvm_analysis_port #(writeback_out_transaction) monitored_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    monitored_ap = new("monitored_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(writeback_out_configuration)::get(this, "", "configuration", configuration))
      `uvm_fatal("WB_CFG", "Missing agent configuration");
    if (configuration == null) `uvm_fatal("WB_CFG", "Null agent configuration");
    if (configuration.is_active != UVM_PASSIVE) `uvm_fatal("WB_ACTIVE", "Writeback agents must be passive");
    is_active             = UVM_PASSIVE;
    monitor               = writeback_out_monitor::type_id::create("monitor", this);
    monitor.configuration = configuration;
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.monitored_ap.connect(monitored_ap);
  endfunction
endclass
