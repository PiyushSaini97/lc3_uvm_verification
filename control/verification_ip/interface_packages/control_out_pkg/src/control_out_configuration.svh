// control_out_configuration
class control_out_configuration extends uvm_object;
  `uvm_object_utils(control_out_configuration)

  uvm_active_passive_enum         is_active = UVM_PASSIVE;
  string                          interface_name;
  bit                             has_coverage               = 1;
  bit                             enable_transaction_viewing = 1;

  virtual control_out_monitor_bfm monitor_bfm;

  control_out_sequencer           sequencer;   // unused: passive agent

  function new(string name = "control_out_configuration");
    super.new(name);
  endfunction

  function void initialize(uvm_active_passive_enum activity, string agent_path, string interface_name);
    this.is_active      = activity;
    this.interface_name = interface_name;
    if (is_active == UVM_ACTIVE)
      `uvm_fatal("CFG", "control_out agent only monitors internal LC3 signals; activity must be UVM_PASSIVE")

    if (!uvm_config_db #(virtual control_out_monitor_bfm)::get(null, "*", interface_name, monitor_bfm))
      `uvm_fatal("CFG", {"control_out_monitor_bfm not found for interface name: ", interface_name})

    uvm_config_db #(control_out_configuration)::set(null, agent_path, "configuration", this);
  endfunction

  virtual function string convert2string();
    return $sformatf("is_active=%s interface_name=%s has_coverage=%0b",
                     is_active.name(), interface_name, has_coverage);
  endfunction
endclass : control_out_configuration
