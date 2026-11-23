class lc3_env_configuration extends uvm_object;
  `uvm_object_utils(lc3_env_configuration)
  fetch_env_configuration     fetch_env_config;
  decode_env_configuration    decode_env_config;
  execute_env_configuration   execute_env_config;
  memaccess_env_configuration memaccess_env_config;
  control_env_configuration   control_env_config;
  writeback_env_configuration writeback_env_config;
  imem_configuration          imem_config;
  dmem_configuration          dmem_config;
  function new(string name = "lc3_env_configuration");
    super.new(name);
    fetch_env_config     = fetch_env_configuration::type_id::create("fetch_env_config");
    decode_env_config    = decode_env_configuration::type_id::create("decode_env_config");
    execute_env_config   = execute_env_configuration::type_id::create("execute_env_config");
    memaccess_env_config = memaccess_env_configuration::type_id::create("memaccess_env_config");
    control_env_config   = control_env_configuration::type_id::create("control_env_config");
    writeback_env_config = writeback_env_configuration::type_id::create("writeback_env_config");
    imem_config          = imem_configuration::type_id::create("imem_config");
    dmem_config          = dmem_configuration::type_id::create("dmem_config");
  endfunction
  function void initialize(string environment_path);
    fetch_env_config.initialize({environment_path, ".fetch_env"}, '{"fetch_in_if", "fetch_out_if"},
                                '{UVM_PASSIVE, UVM_PASSIVE});
    decode_env_config.initialize({environment_path, ".decode_env"}, '{"decode_in_if", "decode_out_if"},
                                 '{UVM_PASSIVE, UVM_PASSIVE});
    execute_env_config.initialize({environment_path, ".execute_env"}, '{"execute_in_if", "execute_out_if"},
                                  '{UVM_PASSIVE, UVM_PASSIVE});
    memaccess_env_config.initialize({environment_path, ".memaccess_env"},
                                    '{"memaccess_in_if", "memaccess_out_if"}, '{UVM_PASSIVE, UVM_PASSIVE});
    control_env_config.initialize({environment_path, ".control_env"}, '{"control_in_if", "control_out_if"},
                                  '{UVM_PASSIVE, UVM_PASSIVE});
    writeback_env_config.initialize({environment_path, ".writeback_env"},
                                    '{"writeback_in_if", "writeback_out_if"}, '{UVM_PASSIVE, UVM_PASSIVE});
    imem_config.initialize({environment_path, ".imem_agent"}, "imem_if");
    dmem_config.initialize({environment_path, ".dmem_agent"}, "dmem_if");
    uvm_config_db#(lc3_env_configuration)::set(null, environment_path, "configuration", this);
  endfunction
endclass
