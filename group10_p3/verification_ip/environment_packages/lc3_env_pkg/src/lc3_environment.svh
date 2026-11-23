class lc3_environment extends uvm_env;
  `uvm_component_utils(lc3_environment)
  lc3_env_configuration configuration;
  fetch_environment     fetch_env;
  decode_environment    decode_env;
  execute_environment   execute_env;
  memaccess_environment memaccess_env;
  control_environment   control_env;
  writeback_environment writeback_env;
  imem_agent            imem_agent_h;
  dmem_agent            dmem_agent_h;
  lc3_predictor         predictor;
  lc3_scoreboard        scoreboard;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(lc3_env_configuration)::get(this, "", "configuration", configuration))
      `uvm_fatal("LC3_MISSING_CFG", "LC3 configuration missing");
    fetch_env     = fetch_environment::type_id::create("fetch_env", this);
    decode_env    = decode_environment::type_id::create("decode_env", this);
    execute_env   = execute_environment::type_id::create("execute_env", this);
    memaccess_env = memaccess_environment::type_id::create("memaccess_env", this);
    control_env   = control_environment::type_id::create("control_env", this);
    writeback_env = writeback_environment::type_id::create("writeback_env", this);
    imem_agent_h  = imem_agent::type_id::create("imem_agent", this);
    dmem_agent_h  = dmem_agent::type_id::create("dmem_agent", this);
    predictor     = lc3_predictor::type_id::create("predictor", this);
    scoreboard    = lc3_scoreboard::type_id::create("scoreboard", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    imem_agent_h.driver.expected_ap.connect(predictor.imem_export);
    predictor.imem_ap.connect(scoreboard.imem_expected);
    imem_agent_h.monitored_ap.connect(scoreboard.imem_actual);
    dmem_agent_h.driver.expected_ap.connect(predictor.dmem_export);
    predictor.dmem_ap.connect(scoreboard.dmem_expected);
    dmem_agent_h.monitored_ap.connect(scoreboard.dmem_actual);
  endfunction
  function void end_of_elaboration_phase(uvm_phase phase);
    if(fetch_env.fetch_in_agent_h.get_is_active()!=UVM_PASSIVE || fetch_env.fetch_out_agent_h.get_is_active()!=UVM_PASSIVE)
      `uvm_fatal("LC3_ACTIVE_STAGE", "fetch not passive");
    if(decode_env.decode_in_agent_h.get_is_active()!=UVM_PASSIVE || decode_env.decode_out_agent_h.get_is_active()!=UVM_PASSIVE)
      `uvm_fatal("LC3_ACTIVE_STAGE", "decode not passive");
    if(execute_env.execute_in_agent_h.get_is_active()!=UVM_PASSIVE || execute_env.execute_out_agent_h.get_is_active()!=UVM_PASSIVE)
      `uvm_fatal("LC3_ACTIVE_STAGE", "execute not passive");
    if(memaccess_env.memaccess_in_agent_h.get_is_active()!=UVM_PASSIVE || memaccess_env.memaccess_out_agent_h.get_is_active()!=UVM_PASSIVE)
      `uvm_fatal("LC3_ACTIVE_STAGE", "memaccess not passive");
    if(control_env.control_in_agent_h.get_is_active()!=UVM_PASSIVE || control_env.control_out_agent_h.get_is_active()!=UVM_PASSIVE)
      `uvm_fatal("LC3_ACTIVE_STAGE", "control not passive");
    if(writeback_env.writeback_in_agent_h.get_is_active()!=UVM_PASSIVE || writeback_env.writeback_out_agent_h.get_is_active()!=UVM_PASSIVE)
      `uvm_fatal("LC3_ACTIVE_STAGE", "writeback not passive");
  endfunction
endclass
