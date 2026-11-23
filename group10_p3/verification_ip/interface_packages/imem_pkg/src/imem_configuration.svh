class imem_configuration extends uvm_object;
  `uvm_object_utils(imem_configuration)
  bit                      has_coverage = 1;  // instruction coverage (imem_coverage) on every fetch
  virtual imem_driver_bfm  driver_bfm;
  virtual imem_monitor_bfm monitor_bfm;
  function new(string name = "imem_configuration");
    super.new(name);
  endfunction
  function void initialize(string path, string key);
    if (!uvm_config_db#(virtual imem_driver_bfm)::get(
            null, "*", key, driver_bfm
        ) || !uvm_config_db#(virtual imem_monitor_bfm)::get(
            null, "*", key, monitor_bfm
        ))
      `uvm_fatal("LC3_MISSING_BFM", {"Missing memory BFMs: ", key});
    uvm_config_db#(imem_configuration)::set(null, path, "configuration", this);
  endfunction
endclass
