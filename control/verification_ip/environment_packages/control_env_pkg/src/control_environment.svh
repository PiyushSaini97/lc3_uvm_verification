// control_environment
// Same topology as P2's decode_environment:
//   control_in_agent  --monitored_ap--> predictor --predicted_ap--> scoreboard.expected_export
//   control_out_agent --monitored_ap------------------------------> scoreboard.actual_export
class control_environment extends uvm_env;
  `uvm_component_utils(control_environment)

  control_env_configuration cfg;

  control_in_agent   control_in_agent_h;
  control_out_agent  control_out_agent_h;
  control_predictor  predictor;
  control_scoreboard scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(control_env_configuration)::get(this, "", "control_env_configuration", cfg))
      `uvm_fatal("NOCFG", {"control_env_configuration must be set for: ", get_full_name()})

    // Instance names must match the agent paths used in control_env_configuration::initialize().
    control_in_agent_h  = control_in_agent  ::type_id::create("control_in_agent",  this);
    control_out_agent_h = control_out_agent ::type_id::create("control_out_agent", this);
    predictor           = control_predictor ::type_id::create("predictor",         this);
    scoreboard          = control_scoreboard::type_id::create("scoreboard",        this);
    scoreboard.max_mismatch_prints = cfg.max_mismatch_prints;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    control_in_agent_h.monitored_ap.connect(predictor.analysis_export);
    predictor.predicted_ap.connect(scoreboard.expected_export);
    control_out_agent_h.monitored_ap.connect(scoreboard.actual_export);
  endfunction
endclass : control_environment
