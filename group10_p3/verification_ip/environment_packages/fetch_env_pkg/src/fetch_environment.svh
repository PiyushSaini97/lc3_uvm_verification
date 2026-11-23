class fetch_environment extends uvm_env;
  `uvm_component_utils(fetch_environment)

  fetch_env_configuration cfg;

  fetch_in_agent          fetch_in_agent_h;
  fetch_out_agent         fetch_out_agent_h;
  fetch_predictor         predictor;
  fetch_scoreboard        scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(fetch_env_configuration)::get(this, "", "fetch_env_configuration", cfg))
      `uvm_fatal("NOCFG", {"fetch_env_configuration must be set for: ", get_full_name()});

    fetch_in_agent_h  = fetch_in_agent::type_id::create("fetch_in_agent", this);
    fetch_out_agent_h = fetch_out_agent::type_id::create("fetch_out_agent", this);
    predictor         = fetch_predictor::type_id::create("predictor", this);
    scoreboard        = fetch_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    fetch_in_agent_h.monitored_ap.connect(predictor.analysis_export);
    predictor.predicted_ap.connect(scoreboard.expected_export);
    fetch_out_agent_h.monitored_ap.connect(scoreboard.actual_export);
  endfunction
endclass : fetch_environment
