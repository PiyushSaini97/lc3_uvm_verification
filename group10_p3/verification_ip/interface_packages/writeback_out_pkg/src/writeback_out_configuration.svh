class writeback_out_configuration extends uvm_object;
  `uvm_object_utils(writeback_out_configuration)
  uvm_active_passive_enum           is_active    = UVM_PASSIVE;
  virtual writeback_out_monitor_bfm monitor_bfm;

  function new(string name = "writeback_out_configuration");
    super.new(name);
  endfunction

  function void initialize(string agent_path, string bfm_key);
    if (is_active != UVM_PASSIVE) `uvm_fatal("WB_ACTIVE", "Writeback agents must be passive");
    if (!uvm_config_db#(virtual writeback_out_monitor_bfm)::get(null, "*", bfm_key, monitor_bfm))
      `uvm_fatal("WB_BFM", {"Missing BFM: ", bfm_key});
    uvm_config_db#(writeback_out_configuration)::set(null, agent_path, "configuration", this);
  endfunction
endclass
