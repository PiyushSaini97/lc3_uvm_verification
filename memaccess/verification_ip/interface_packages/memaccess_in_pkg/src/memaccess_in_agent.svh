// memaccess_in_agent
// Monitor (+ optional coverage) always; sequencer + driver when ACTIVE.
// Same build/connect structure as P2's decode_in_agent and control_in_agent.
class memaccess_in_agent extends uvm_agent;
  `uvm_component_utils(memaccess_in_agent)

  memaccess_in_configuration configuration;
  memaccess_in_sequencer     sequencer;
  memaccess_in_driver        driver;
  memaccess_in_monitor       monitor;
  memaccess_in_coverage      coverage;
  uvm_analysis_port #(memaccess_in_transaction) monitored_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(memaccess_in_configuration)::get(this, "", "configuration", configuration))
      `uvm_fatal("CFG", {"memaccess_in_configuration not found for: ", get_full_name()})

    monitor               = memaccess_in_monitor::type_id::create("monitor", this);
    monitor.configuration = configuration;
    monitored_ap          = new("monitored_ap", this);

    if (configuration.has_coverage)
      coverage = memaccess_in_coverage::type_id::create("coverage", this);

    if (configuration.is_active == UVM_ACTIVE) begin
      sequencer               = memaccess_in_sequencer::type_id::create("sequencer", this);
      driver                  = memaccess_in_driver::type_id::create("driver", this);
      driver.configuration    = configuration;
      configuration.sequencer = sequencer;
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.monitored_ap.connect(monitored_ap);
    if (configuration.has_coverage)
      monitor.monitored_ap.connect(coverage.analysis_export);
    if (configuration.is_active == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass : memaccess_in_agent
