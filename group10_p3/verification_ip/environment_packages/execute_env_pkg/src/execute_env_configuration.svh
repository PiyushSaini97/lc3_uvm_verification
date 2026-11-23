// execute_env_configuration
// Same contract as control_env_configuration / decode_env_configuration:
//   * constructs the agent configurations
//   * initialize() receives the environment path, interface names and activities from
//     the parent (the test here, lc3_env_configuration at LC3 level) and hands each
//     agent its path, interface name and activity
//   * publishes itself so execute_environment can get() it in build_phase
class execute_env_configuration extends uvm_object;
  `uvm_object_utils(execute_env_configuration)

  execute_in_configuration  execute_in_config;
  execute_out_configuration execute_out_config;

  // Stop printing individual mismatches after this many (they are still counted).
  int unsigned              max_mismatch_prints = 20;

  function new(string name = "execute_env_configuration");
    super.new(name);
    execute_in_config  = execute_in_configuration::type_id::create("execute_in_config");
    execute_out_config = execute_out_configuration::type_id::create("execute_out_config");
  endfunction

  // interface_names[0]/interface_activity[0] -> execute_in agent
  // interface_names[1]/interface_activity[1] -> execute_out agent
  function void initialize(string environment_path, string interface_names[],
                           uvm_active_passive_enum interface_activity[]);
    if (interface_names.size() != 2 || interface_activity.size() != 2)
      `uvm_fatal("CFG", "execute environment expects 2 interface names and 2 activities");

    execute_in_config.initialize(interface_activity[0], {environment_path, ".execute_in_agent"},
                                 interface_names[0]);
    execute_out_config.initialize(interface_activity[1], {environment_path, ".execute_out_agent"},
                                  interface_names[1]);

    uvm_config_db#(execute_env_configuration)::set(null, environment_path, "execute_env_configuration", this);
  endfunction

  virtual function string convert2string();
    return {
      "execute_in: ",
      execute_in_config.convert2string(),
      " | execute_out: ",
      execute_out_config.convert2string()
    };
  endfunction
endclass : execute_env_configuration
