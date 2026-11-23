class dmem_configuration extends uvm_object;
  `uvm_object_utils(dmem_configuration)
  virtual dmem_driver_bfm  driver_bfm;
  virtual dmem_monitor_bfm monitor_bfm;
  function new(string name = "dmem_configuration");
    super.new(name);
  endfunction
  function void initialize(string path, string key);
    if (!uvm_config_db#(virtual dmem_driver_bfm)::get(
            null, "*", key, driver_bfm
        ) || !uvm_config_db#(virtual dmem_monitor_bfm)::get(
            null, "*", key, monitor_bfm
        ))
      `uvm_fatal("LC3_MISSING_BFM", {"Missing memory BFMs: ", key});
    uvm_config_db#(dmem_configuration)::set(null, path, "configuration", this);
  endfunction
endclass
