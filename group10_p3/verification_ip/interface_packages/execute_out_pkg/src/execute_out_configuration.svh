class execute_out_configuration extends uvm_object;
  `uvm_object_utils(execute_out_configuration)
  uvm_active_passive_enum         is_active                  = UVM_PASSIVE;
  bit                             enable_transaction_viewing = 0;
  virtual execute_out_monitor_bfm monitor_bfm;
  function new(string name = "execute_out_configuration");
    super.new(name);
  endfunction
  function void initialize(uvm_active_passive_enum activity, string agent_path, string interface_name);
    if (activity != UVM_PASSIVE) `uvm_fatal("LC3_ACTIVE_STAGE", "Stage agents must be passive");
    is_active = activity;
    if (!uvm_config_db#(virtual execute_out_monitor_bfm)::get(null, "*", interface_name, monitor_bfm))
      `uvm_fatal("LC3_MISSING_BFM", {"Missing ", interface_name});
    uvm_config_db#(execute_out_configuration)::set(null, agent_path, "configuration", this);
  endfunction
  function string convert2string();
    return "passive";
  endfunction
endclass
