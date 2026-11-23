class fetch_env_configuration extends uvm_object;
  `uvm_object_utils(fetch_env_configuration)

  fetch_in_configuration  fetch_in_config;
  fetch_out_configuration fetch_out_config;

  function new(string name = "fetch_env_configuration");
    super.new(name);
    fetch_in_config  = fetch_in_configuration::type_id::create("fetch_in_config");
    fetch_out_config = fetch_out_configuration::type_id::create("fetch_out_config");
  endfunction

  function void initialize(string environment_path, string interface_names[],
                           uvm_active_passive_enum interface_activity[]);
    if (interface_names.size() != 2 || interface_activity.size() != 2)
      `uvm_fatal("CFG", "fetch environment expects 2 interface names and 2 activities");

    fetch_in_config.initialize(interface_activity[0], {environment_path, ".fetch_in_agent"},
                               interface_names[0]);
    fetch_out_config.initialize(interface_activity[1], {environment_path, ".fetch_out_agent"},
                                interface_names[1]);

    uvm_config_db#(fetch_env_configuration)::set(null, environment_path, "fetch_env_configuration", this);
  endfunction
endclass : fetch_env_configuration
