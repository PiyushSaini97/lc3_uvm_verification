// memaccess_out_configuration
// Passive in both benches: nothing except MemAccess ever drives its outputs, so an
// ACTIVE setting is a configuration error and is caught here rather than producing
// a confusing missing-BFM fatal later.
class memaccess_out_configuration extends uvm_object;
  `uvm_object_utils(memaccess_out_configuration)

  uvm_active_passive_enum           is_active = UVM_PASSIVE;
  string                            interface_name;
  bit                               has_coverage               = 1;
  bit                               enable_transaction_viewing = 1;

  virtual memaccess_out_monitor_bfm monitor_bfm;

  memaccess_out_sequencer           sequencer;   // unused: passive agent

  function new(string name = "memaccess_out_configuration");
    super.new(name);
  endfunction

  function void initialize(uvm_active_passive_enum activity, string agent_path, string interface_name);
    this.is_active      = activity;
    this.interface_name = interface_name;
    if (is_active == UVM_ACTIVE)
      `uvm_fatal("CFG", "memaccess_out agent only observes MemAccess outputs; activity must be UVM_PASSIVE")

    if (!uvm_config_db #(virtual memaccess_out_monitor_bfm)::get(null, "*", interface_name, monitor_bfm))
      `uvm_fatal("CFG", {"memaccess_out_monitor_bfm not found for interface name: ", interface_name})

    uvm_config_db #(memaccess_out_configuration)::set(null, agent_path, "configuration", this);
  endfunction

  virtual function string convert2string();
    return $sformatf("is_active=%s interface_name=%s has_coverage=%0b",
                     is_active.name(), interface_name, has_coverage);
  endfunction
endclass : memaccess_out_configuration
