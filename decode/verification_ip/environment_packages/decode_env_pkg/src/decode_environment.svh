class decode_environment extends uvm_env;
  `uvm_component_utils(decode_environment)

  decode_env_configuration cfg;

  decode_in_agent   decode_in_agent_h;
  decode_out_agent  decode_out_agent_h;
  decode_predictor  predictor;
  decode_scoreboard scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(decode_env_configuration)::get(this, "", "decode_env_configuration", cfg))
      `uvm_fatal("NOCFG", {"decode_env_configuration must be set for: ", get_full_name()})

    decode_in_agent_h  = decode_in_agent  ::type_id::create("decode_in_agent",  this);
    decode_out_agent_h = decode_out_agent ::type_id::create("decode_out_agent", this);
    predictor          = decode_predictor ::type_id::create("predictor",        this);
    scoreboard         = decode_scoreboard::type_id::create("scoreboard",       this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    decode_in_agent_h.monitored_ap.connect(predictor.analysis_export);
    predictor.predicted_ap.connect(scoreboard.expected_export);
    decode_out_agent_h.monitored_ap.connect(scoreboard.actual_export);
  endfunction
endclass : decode_environment
