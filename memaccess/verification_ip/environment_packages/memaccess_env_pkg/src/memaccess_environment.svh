// memaccess_environment
// Same topology as P2's decode_environment and control_environment:
//   memaccess_in_agent  --monitored_ap--> predictor --predicted_ap--> scoreboard.expected_export
//   memaccess_out_agent --monitored_ap--------------------------------> scoreboard.actual_export
class memaccess_environment extends uvm_env;
  `uvm_component_utils(memaccess_environment)

  memaccess_env_configuration cfg;

  memaccess_in_agent   memaccess_in_agent_h;
  memaccess_out_agent  memaccess_out_agent_h;
  memaccess_predictor  predictor;
  memaccess_scoreboard scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(memaccess_env_configuration)::get(this, "", "memaccess_env_configuration", cfg))
      `uvm_fatal("NOCFG", {"memaccess_env_configuration must be set for: ", get_full_name()})

    // Instance names must match the agent paths used in memaccess_env_configuration::initialize().
    memaccess_in_agent_h  = memaccess_in_agent  ::type_id::create("memaccess_in_agent",  this);
    memaccess_out_agent_h = memaccess_out_agent ::type_id::create("memaccess_out_agent", this);
    predictor             = memaccess_predictor ::type_id::create("predictor",           this);
    scoreboard            = memaccess_scoreboard::type_id::create("scoreboard",          this);
    scoreboard.max_mismatch_prints = cfg.max_mismatch_prints;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    memaccess_in_agent_h.monitored_ap.connect(predictor.analysis_export);
    predictor.predicted_ap.connect(scoreboard.expected_export);
    memaccess_out_agent_h.monitored_ap.connect(scoreboard.actual_export);
  endfunction
endclass : memaccess_environment
