// execute_out_configuration
class execute_out_configuration extends uvm_object;
  `uvm_object_utils(execute_out_configuration)

  uvm_active_passive_enum          is_active = UVM_PASSIVE;
  string                           interface_name;
  bit                              has_coverage               = 1;
  bit                              enable_transaction_viewing = 1;

  virtual execute_out_monitor_bfm  monitor_bfm;

  function new(string name = "execute_out_configuration");
    super.new(name);
  endfunction

  function void initialize(uvm_active_passive_enum activity, string agent_path, string interface_name);
    this.is_active      = activity;
    this.interface_name = interface_name;
    if (is_active == UVM_ACTIVE)
      `uvm_fatal("CFG", "execute_out agent only monitors Execute outputs; activity must be UVM_PASSIVE")

    if (!uvm_config_db #(virtual execute_out_monitor_bfm)::get(null, "*", interface_name, monitor_bfm))
      `uvm_fatal("CFG", {"execute_out_monitor_bfm not found for interface name: ", interface_name})

    uvm_config_db #(execute_out_configuration)::set(null, agent_path, "configuration", this);
  endfunction

  virtual function string convert2string();
    return $sformatf("is_active=%s interface_name=%s has_coverage=%0b",
                     is_active.name(), interface_name, has_coverage);
  endfunction
endclass : execute_out_configuration
