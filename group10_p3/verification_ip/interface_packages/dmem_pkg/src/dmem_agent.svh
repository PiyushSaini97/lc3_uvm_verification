class dmem_agent extends uvm_agent;
  `uvm_component_utils(dmem_agent)
  dmem_configuration                    configuration;
  dmem_sequencer                        sequencer;
  dmem_driver                           driver;
  dmem_monitor                          monitor;
  uvm_analysis_port #(dmem_transaction) monitored_ap;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    monitored_ap = new("monitored_ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(dmem_configuration)::get(
            this, "", "configuration", configuration
        ) || configuration == null)
      `uvm_fatal("LC3_MISSING_CFG", "Memory config missing");
    is_active             = UVM_ACTIVE;
    sequencer             = dmem_sequencer::type_id::create("sequencer", this);
    driver                = dmem_driver::type_id::create("driver", this);
    driver.configuration  = configuration;
    driver.sequencer      = sequencer;
    monitor               = dmem_monitor::type_id::create("monitor", this);
    monitor.configuration = configuration;
  endfunction
  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    monitor.monitored_ap.connect(monitored_ap);
  endfunction
endclass
