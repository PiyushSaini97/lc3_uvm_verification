// memaccess_in_configuration
// Agent configuration: activity, interface name, BFM handles; publishes itself to the
// agent through uvm_config_db (same flow as P2's decode_in_configuration).
//
//   memaccess block bench : UVM_ACTIVE  -> driver BFM drives the five input nets
//   LC3 top bench         : UVM_PASSIVE -> monitor only (the real Controller and
//                                          Execute drive them)
class memaccess_in_configuration extends uvm_object;
  `uvm_object_utils(memaccess_in_configuration)

  uvm_active_passive_enum          is_active = UVM_PASSIVE;
  string                           interface_name;
  bit                              has_coverage               = 1;
  bit                              enable_transaction_viewing = 1;

  virtual memaccess_in_driver_bfm  driver_bfm;
  virtual memaccess_in_monitor_bfm monitor_bfm;

  memaccess_in_sequencer           sequencer;   // set by the agent when ACTIVE

  function new(string name = "memaccess_in_configuration");
    super.new(name);
  endfunction

  function void initialize(uvm_active_passive_enum activity, string agent_path, string interface_name);
    this.is_active      = activity;
    this.interface_name = interface_name;

    if (!uvm_config_db #(virtual memaccess_in_monitor_bfm)::get(null, "*", interface_name, monitor_bfm))
      `uvm_fatal("CFG", {"memaccess_in_monitor_bfm not found for interface name: ", interface_name})
    if (is_active == UVM_ACTIVE)
      if (!uvm_config_db #(virtual memaccess_in_driver_bfm)::get(null, "*", interface_name, driver_bfm))
        `uvm_fatal("CFG", {"memaccess_in_driver_bfm not found for interface name: ", interface_name,
                           " (ACTIVE is only for the memaccess block bench)"})

    uvm_config_db #(memaccess_in_configuration)::set(null, agent_path, "configuration", this);
  endfunction

  virtual function string convert2string();
    return $sformatf("is_active=%s interface_name=%s has_coverage=%0b",
                     is_active.name(), interface_name, has_coverage);
  endfunction
endclass : memaccess_in_configuration
