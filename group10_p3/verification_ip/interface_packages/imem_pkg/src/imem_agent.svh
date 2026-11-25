class imem_agent extends uvm_agent;
  `uvm_component_utils(imem_agent)
  imem_configuration                    configuration;
  imem_sequencer                        sequencer;
  imem_driver                           driver;
  imem_monitor                          monitor;
  imem_coverage                         coverage;
  imem_pipeline_coverage                pipeline_coverage;
  uvm_analysis_port #(imem_transaction) monitored_ap;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    monitored_ap = new("monitored_ap", this);
  endfunction
  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(imem_configuration)::get(
            this, "", "configuration", configuration
        ) || configuration == null)
      `uvm_fatal("LC3_MISSING_CFG", "Memory config missing");
    is_active             = UVM_ACTIVE;
    sequencer             = imem_sequencer::type_id::create("sequencer", this);
    driver                = imem_driver::type_id::create("driver", this);
    driver.configuration  = configuration;
    driver.sequencer      = sequencer;
    monitor               = imem_monitor::type_id::create("monitor", this);
    monitor.configuration = configuration;
    // Created through the factory so another coverage model can be substituted with a type override.
    if (configuration.has_coverage) coverage = imem_coverage::type_id::create("coverage", this);
    if (configuration.has_coverage) pipeline_coverage = imem_pipeline_coverage::type_id::create("pipeline_coverage", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    monitor.monitored_ap.connect(monitored_ap);
    if (coverage != null) monitored_ap.connect(coverage.analysis_export);
    if (pipeline_coverage != null) monitored_ap.connect(pipeline_coverage.analysis_export);
  endfunction
endclass
