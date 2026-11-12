// control_out_agent
// Passive agent: monitor (+ optional coverage).
class control_out_agent extends uvm_agent;
  `uvm_component_utils(control_out_agent)

  control_out_configuration configuration;
  control_out_monitor       monitor;
  control_out_coverage      coverage;
  uvm_analysis_port #(control_out_transaction) monitored_ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(control_out_configuration)::get(this, "", "configuration", configuration))
      `uvm_fatal("CFG", {"control_out_configuration not found for: ", get_full_name()})

    monitor               = control_out_monitor::type_id::create("monitor", this);
    monitor.configuration = configuration;
    monitored_ap          = new("monitored_ap", this);

    if (configuration.has_coverage)
      coverage = control_out_coverage::type_id::create("coverage", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.monitored_ap.connect(monitored_ap);
    if (configuration.has_coverage)
      monitor.monitored_ap.connect(coverage.analysis_export);
  endfunction
endclass : control_out_agent
