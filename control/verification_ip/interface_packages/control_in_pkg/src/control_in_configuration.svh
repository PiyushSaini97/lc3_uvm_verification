// control_in_configuration
// Agent configuration: activity, interface name, BFM handles; publishes itself to the
// agent through uvm_config_db (same flow as P2's decode_in_configuration).
//
//   control block bench : UVM_ACTIVE  -> driver BFM emulates the surrounding pipeline
//   LC3 top bench       : UVM_PASSIVE -> monitor only (real Decode/Execute/WB drive)
class control_in_configuration extends uvm_object;
  `uvm_object_utils(control_in_configuration)

  uvm_active_passive_enum        is_active = UVM_PASSIVE;
  string                         interface_name;
  bit                            has_coverage               = 1;
  bit                            enable_transaction_viewing = 1;

  virtual control_in_driver_bfm  driver_bfm;
  virtual control_in_monitor_bfm monitor_bfm;

  control_in_sequencer           sequencer;   // set by the agent when ACTIVE

  function new(string name = "control_in_configuration");
    super.new(name);
  endfunction

  function void initialize(uvm_active_passive_enum activity, string agent_path, string interface_name);
    this.is_active      = activity;
    this.interface_name = interface_name;

    if (!uvm_config_db #(virtual control_in_monitor_bfm)::get(null, "*", interface_name, monitor_bfm))
      `uvm_fatal("CFG", {"control_in_monitor_bfm not found for interface name: ", interface_name})
    if (is_active == UVM_ACTIVE)
      if (!uvm_config_db #(virtual control_in_driver_bfm)::get(null, "*", interface_name, driver_bfm))
        `uvm_fatal("CFG", {"control_in_driver_bfm not found for interface name: ", interface_name,
                           " (ACTIVE is only for the control block bench)"})

    uvm_config_db #(control_in_configuration)::set(null, agent_path, "configuration", this);
  endfunction

  virtual function string convert2string();
    return $sformatf("is_active=%s interface_name=%s has_coverage=%0b",
                     is_active.name(), interface_name, has_coverage);
  endfunction
endclass : control_in_configuration
