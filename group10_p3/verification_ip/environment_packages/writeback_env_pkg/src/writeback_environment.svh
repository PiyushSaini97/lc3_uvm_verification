class writeback_environment extends uvm_env;
  `uvm_component_utils(writeback_environment)
  writeback_env_configuration configuration;
  writeback_in_agent          writeback_in_agent_h;
  writeback_out_agent         writeback_out_agent_h;
  writeback_predictor         predictor;
  writeback_scoreboard        scoreboard;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(writeback_env_configuration)::get(
            this, "", "writeback_env_configuration", configuration
        ))
      `uvm_fatal("WB_CFG", "Writeback environment configuration missing");
    if (configuration == null) `uvm_fatal("WB_CFG", "Null environment configuration");
    writeback_in_agent_h     = writeback_in_agent::type_id::create("writeback_in_agent", this);
    writeback_out_agent_h    = writeback_out_agent::type_id::create("writeback_out_agent", this);
    predictor                = writeback_predictor::type_id::create("predictor", this);
    scoreboard               = writeback_scoreboard::type_id::create("scoreboard", this);
    predictor.configuration  = configuration;
    scoreboard.configuration = configuration;
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    writeback_in_agent_h.monitored_ap.connect(predictor.analysis_export);
    predictor.predicted_ap.connect(scoreboard.expected_export);
    writeback_out_agent_h.monitored_ap.connect(scoreboard.actual_export);
  endfunction
endclass
