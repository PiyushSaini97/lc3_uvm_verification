class decode_in_configuration extends uvm_object;
  `uvm_object_utils(decode_in_configuration)

  uvm_active_passive_enum       is_active = UVM_ACTIVE;
  string                        interface_name;
  bit                           has_coverage               = 1;
  bit                           enable_transaction_viewing = 1;

  virtual decode_in_driver_bfm  driver_bfm;
  virtual decode_in_monitor_bfm monitor_bfm;

  decode_in_sequencer           sequencer;

  function new(string name = "decode_in_configuration");
    super.new(name);
  endfunction

  function void initialize(uvm_active_passive_enum activity, string agent_path, string interface_name);
    this.is_active      = activity;
    this.interface_name = interface_name;

    if (!uvm_config_db #(virtual decode_in_monitor_bfm)::get(null, "*", interface_name, monitor_bfm))
      `uvm_fatal("CFG", {"decode_in_monitor_bfm not found for interface name: ", interface_name})
    if (is_active == UVM_ACTIVE)
      if (!uvm_config_db #(virtual decode_in_driver_bfm)::get(null, "*", interface_name, driver_bfm))
        `uvm_fatal("CFG", {"decode_in_driver_bfm not found for interface name: ", interface_name})

    uvm_config_db #(decode_in_configuration)::set(null, agent_path, "configuration", this);
  endfunction

  virtual function string convert2string();
    return $sformatf("is_active=%s interface_name=%s has_coverage=%0b",
                     is_active.name(), interface_name, has_coverage);
  endfunction
endclass : decode_in_configuration
