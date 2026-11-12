class decode_out_configuration extends uvm_object;
  `uvm_object_utils(decode_out_configuration)

  uvm_active_passive_enum        is_active = UVM_PASSIVE;
  string                         interface_name;
  bit                            enable_transaction_viewing = 1;

  virtual decode_out_monitor_bfm monitor_bfm;

  decode_out_sequencer           sequencer;

  function new(string name = "decode_out_configuration");
    super.new(name);
  endfunction

  function void initialize(uvm_active_passive_enum activity, string agent_path, string interface_name);
    this.is_active      = activity;
    this.interface_name = interface_name;
    if (is_active == UVM_ACTIVE)
      `uvm_fatal("CFG", "decode_out agent only monitors DUT outputs; activity must be UVM_PASSIVE")

    if (!uvm_config_db #(virtual decode_out_monitor_bfm)::get(null, "*", interface_name, monitor_bfm))
      `uvm_fatal("CFG", {"decode_out_monitor_bfm not found for interface name: ", interface_name})

    uvm_config_db #(decode_out_configuration)::set(null, agent_path, "configuration", this);
  endfunction

  virtual function string convert2string();
    return $sformatf("is_active=%s interface_name=%s", is_active.name(), interface_name);
  endfunction
endclass : decode_out_configuration
