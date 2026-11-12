class decode_env_configuration extends uvm_object;
  `uvm_object_utils(decode_env_configuration)

  decode_in_configuration  decode_in_config;
  decode_out_configuration decode_out_config;

  function new(string name = "decode_env_configuration");
    super.new(name);
    decode_in_config  = decode_in_configuration ::type_id::create("decode_in_config");
    decode_out_config = decode_out_configuration::type_id::create("decode_out_config");
  endfunction

  function void initialize(string environment_path,
                           string interface_names[],
                           uvm_active_passive_enum interface_activity[]);
    if (interface_names.size() != 2 || interface_activity.size() != 2)
      `uvm_fatal("CFG", "decode environment expects 2 interface names and 2 activities")

    decode_in_config.initialize (interface_activity[0], {environment_path, ".decode_in_agent"},  interface_names[0]);
    decode_out_config.initialize(interface_activity[1], {environment_path, ".decode_out_agent"}, interface_names[1]);

    uvm_config_db#(decode_env_configuration)::set(null, environment_path, "decode_env_configuration", this);
  endfunction
endclass : decode_env_configuration
