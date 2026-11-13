// memaccess_env_configuration
// Same contract as P2's decode_env_configuration and control_env_configuration:
//   * constructs the agent configurations
//   * initialize() receives the environment path, interface names and activities
//     from the parent (here: lc3_env_configuration) and hands each agent its path,
//     interface name and activity
//   * publishes itself so memaccess_environment can get() it in build_phase
class memaccess_env_configuration extends uvm_object;
  `uvm_object_utils(memaccess_env_configuration)

  memaccess_in_configuration  memaccess_in_config;
  memaccess_out_configuration memaccess_out_config;

  // Scoreboard knob: stop printing individual mismatches after this many (they are
  // still counted). A combinational bug repeats on every cycle in that state.
  int unsigned max_mismatch_prints = 20;

  function new(string name = "memaccess_env_configuration");
    super.new(name);
    memaccess_in_config  = memaccess_in_configuration ::type_id::create("memaccess_in_config");
    memaccess_out_config = memaccess_out_configuration::type_id::create("memaccess_out_config");
  endfunction

  // interface_names[0]/interface_activity[0] -> memaccess_in agent
  // interface_names[1]/interface_activity[1] -> memaccess_out agent
  function void initialize(string environment_path,
                           string interface_names[],
                           uvm_active_passive_enum interface_activity[]);
    if (interface_names.size() != 2 || interface_activity.size() != 2)
      `uvm_fatal("CFG", "memaccess environment expects 2 interface names and 2 activities")

    memaccess_in_config.initialize (interface_activity[0], {environment_path, ".memaccess_in_agent"},  interface_names[0]);
    memaccess_out_config.initialize(interface_activity[1], {environment_path, ".memaccess_out_agent"}, interface_names[1]);

    uvm_config_db #(memaccess_env_configuration)::set(null, environment_path, "memaccess_env_configuration", this);
  endfunction

  virtual function string convert2string();
    return {"memaccess_in: ",  memaccess_in_config.convert2string(),
            " | memaccess_out: ", memaccess_out_config.convert2string()};
  endfunction
endclass : memaccess_env_configuration
