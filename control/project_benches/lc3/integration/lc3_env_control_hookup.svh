// ============================================================================
// How control_env plugs into the LC3 environment (lc3_env_pkg).
// These are excerpts to merge into your lc3_env_configuration / lc3_environment;
// they are not standalone files.
// ============================================================================

// ---- lc3_env_pkg.sv ---------------------------------------------------------
//   import control_env_pkg::*;      // alongside decode_env_pkg, fetch_env_pkg, ...

// ---- lc3_env_configuration.svh ----------------------------------------------
//   control_env_configuration control_env_config;
//
//   function new(string name = "lc3_env_configuration");
//     super.new(name);
//     ...
//     control_env_config = control_env_configuration::type_id::create("control_env_config");
//   endfunction
//
//   function void initialize(string environment_path, ...);
//     ...
//     // Both control agents are passive (P3 slide 7: "Passive, monitoring only agents").
//     control_env_config.initialize({environment_path, ".control_env"},
//                                   '{"control_in_if", "control_out_if"},
//                                   '{UVM_PASSIVE,     UVM_PASSIVE});
//     ...
//   endfunction

// ---- lc3_environment.svh -----------------------------------------------------
//   control_environment control_env;
//
//   function void build_phase(uvm_phase phase);
//     ...
//     // Instance name MUST be "control_env" to match the path given above.
//     control_env = control_environment::type_id::create("control_env", this);
//   endfunction
//
//   // No connect_phase work needed: control_env is self-contained (its own agents,
//   // predictor and scoreboard).

// ---- Test-level knobs (optional, in the test's build_phase after initialize) ----
//   env_config.control_env_config.max_mismatch_prints                   = 50;
//   env_config.control_env_config.control_in_config.enable_transaction_viewing = 0; // regressions
