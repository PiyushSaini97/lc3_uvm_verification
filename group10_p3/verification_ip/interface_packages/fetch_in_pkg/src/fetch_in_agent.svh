class fetch_in_agent extends uvm_agent;
  `uvm_component_utils(fetch_in_agent)
  fetch_in_configuration                    configuration;
  fetch_in_monitor                          monitor;

  uvm_analysis_port #(fetch_in_transaction) monitored_ap;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    monitored_ap = new("monitored_ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(fetch_in_configuration)::get(
            this, "", "configuration", configuration
        ) || configuration == null)
      `uvm_fatal("LC3_MISSING_CFG", "Missing stage configuration");
    if (configuration.is_active != UVM_PASSIVE) `uvm_fatal("LC3_ACTIVE_STAGE", "Active stage prohibited");
    is_active             = UVM_PASSIVE;
    monitor               = fetch_in_monitor::type_id::create("monitor", this);
    monitor.configuration = configuration;

  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.monitored_ap.connect(monitored_ap);

  endfunction
endclass
