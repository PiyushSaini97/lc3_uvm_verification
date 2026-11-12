class decode_out_agent extends uvm_agent;
  `uvm_component_utils(decode_out_agent)

  decode_out_configuration configuration;
  decode_out_monitor       monitor;
  uvm_analysis_port #(decode_out_transaction) monitored_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(decode_out_configuration)::get(this, "", "configuration", configuration))
      `uvm_fatal("CFG", {"decode_out_configuration not found for: ", get_full_name()})

    monitor               = decode_out_monitor::type_id::create("monitor", this);
    monitor.configuration = configuration;
    monitored_ap          = new("monitored_ap", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.monitored_ap.connect(monitored_ap);
  endfunction
endclass : decode_out_agent
