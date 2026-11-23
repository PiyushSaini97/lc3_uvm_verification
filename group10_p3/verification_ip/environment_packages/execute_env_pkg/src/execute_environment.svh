// execute_environment
//   execute_in_agent  --monitored_ap--> predictor --predicted_ap--> scoreboard.expected_export
//   execute_out_agent --monitored_ap------------------------------> scoreboard.actual_export
class execute_environment extends uvm_env;
  `uvm_component_utils(execute_environment)

  execute_env_configuration cfg;

  execute_in_agent          execute_in_agent_h;
  execute_out_agent         execute_out_agent_h;
  execute_predictor         predictor;
  execute_scoreboard        scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(execute_env_configuration)::get(this, "", "execute_env_configuration", cfg))
      `uvm_fatal("NOCFG", {"execute_env_configuration must be set for: ", get_full_name()});

    // Instance names must match the agent paths used in execute_env_configuration::initialize().
    execute_in_agent_h             = execute_in_agent::type_id::create("execute_in_agent", this);
    execute_out_agent_h            = execute_out_agent::type_id::create("execute_out_agent", this);
    predictor                      = execute_predictor::type_id::create("predictor", this);
    scoreboard                     = execute_scoreboard::type_id::create("scoreboard", this);
    scoreboard.max_mismatch_prints = cfg.max_mismatch_prints;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    execute_in_agent_h.monitored_ap.connect(predictor.analysis_export);
    predictor.predicted_ap.connect(scoreboard.expected_export);
    execute_out_agent_h.monitored_ap.connect(scoreboard.actual_export);
  endfunction
endclass : execute_environment
