class writeback_env_configuration extends uvm_object;
  `uvm_object_utils(writeback_env_configuration)
  writeback_in_configuration        writeback_in_config;
  writeback_out_configuration       writeback_out_config;
  int unsigned                      max_pending           = 8;
  int unsigned                      max_mismatch_prints   = 20;
  // Protected RTL does not expose PSR reset value. Enable only after confirmation.
  bit                               check_reset_psr       = 0;
  logic                       [2:0] reset_psr             = 3'b010;

  function new(string name = "writeback_env_configuration");
    super.new(name);
    writeback_in_config  = writeback_in_configuration::type_id::create("writeback_in_config");
    writeback_out_config = writeback_out_configuration::type_id::create("writeback_out_config");
  endfunction

  function void initialize(string environment_path, string interface_names[],
                           uvm_active_passive_enum interface_activity[]);
    if (interface_names.size() != 2 || interface_activity.size() != 2)
      `uvm_fatal("WB_CFG", "Expected two interface names and two activities");
    foreach (interface_activity[i])
    if (interface_activity[i] != UVM_PASSIVE)
      `uvm_fatal("WB_ACTIVE", "Both writeback agents must be passive");
    writeback_in_config.initialize({environment_path, ".writeback_in_agent"}, interface_names[0]);
    writeback_out_config.initialize({environment_path, ".writeback_out_agent"}, interface_names[1]);
    uvm_config_db#(writeback_env_configuration)::set(null, environment_path, "writeback_env_configuration",
                                                     this);
  endfunction
endclass
