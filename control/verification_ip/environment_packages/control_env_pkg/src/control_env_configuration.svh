// control_env_configuration
// Same contract as P2's decode_env_configuration:
//   * constructs the agent configurations
//   * initialize() receives the environment path, interface names and activities
//     from the parent (here: lc3_env_configuration) and hands each agent its path,
//     interface name and activity
//   * publishes itself so control_environment can get() it in build_phase
class control_env_configuration extends uvm_object;
  `uvm_object_utils(control_env_configuration)

  control_in_configuration  control_in_config;
  control_out_configuration control_out_config;

  // Scoreboard knob: stop printing individual mismatches after this many
  // (they are still counted). A controller bug tends to repeat every cycle.
  int unsigned max_mismatch_prints = 20;

  function new(string name = "control_env_configuration");
    super.new(name);
    control_in_config  = control_in_configuration ::type_id::create("control_in_config");
    control_out_config = control_out_configuration::type_id::create("control_out_config");
  endfunction

  // interface_names[0]/interface_activity[0] -> control_in agent
  // interface_names[1]/interface_activity[1] -> control_out agent
  function void initialize(string environment_path,
                           string interface_names[],
                           uvm_active_passive_enum interface_activity[]);
    if (interface_names.size() != 2 || interface_activity.size() != 2)
      `uvm_fatal("CFG", "control environment expects 2 interface names and 2 activities")

    control_in_config.initialize (interface_activity[0], {environment_path, ".control_in_agent"},  interface_names[0]);
    control_out_config.initialize(interface_activity[1], {environment_path, ".control_out_agent"}, interface_names[1]);

    uvm_config_db #(control_env_configuration)::set(null, environment_path, "control_env_configuration", this);
  endfunction

  virtual function string convert2string();
    return {"control_in: ", control_in_config.convert2string(),
            " | control_out: ", control_out_config.convert2string()};
  endfunction
endclass : control_env_configuration
