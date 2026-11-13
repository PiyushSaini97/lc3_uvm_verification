// ============================================================================
// How memaccess_env plugs into the LC3 environment (lc3_env_pkg).
// These are excerpts to merge into your lc3_env_configuration / lc3_environment;
// they are not standalone files.
// ============================================================================

// ---- lc3_env_pkg.sv ---------------------------------------------------------
//   import memaccess_env_pkg::*;   // alongside decode_env_pkg, control_env_pkg, ...

// ---- lc3_env_configuration.svh ----------------------------------------------
//   memaccess_env_configuration memaccess_env_config;
//
//   function new(string name = "lc3_env_configuration");
//     super.new(name);
//     ...
//     memaccess_env_config = memaccess_env_configuration::type_id::create("memaccess_env_config");
//   endfunction
//
//   function void initialize(string environment_path, ...);
//     ...
//     // Both memaccess agents are passive (P3 slide 7: "Passive, monitoring only
//     // agents"). The in agent is ACTIVE only in the standalone memaccess bench.
//     memaccess_env_config.initialize({environment_path, ".memaccess_env"},
//                                     '{"memaccess_in_if", "memaccess_out_if"},
//                                     '{UVM_PASSIVE,       UVM_PASSIVE});
//     ...
//   endfunction

// ---- lc3_environment.svh -----------------------------------------------------
//   memaccess_environment memaccess_env;
//
//   function void build_phase(uvm_phase phase);
//     ...
//     // Instance name MUST be "memaccess_env" to match the path given above.
//     memaccess_env = memaccess_environment::type_id::create("memaccess_env", this);
//   endfunction
//
//   // No connect_phase work needed: memaccess_env is self-contained (its own agents,
//   // predictor and scoreboard).

// ---- Test-level knobs (optional, in the test's build_phase after initialize) ----
//   env_config.memaccess_env_config.max_mismatch_prints                            = 50;
//   env_config.memaccess_env_config.memaccess_in_config.enable_transaction_viewing = 0; // regressions
//   env_config.memaccess_env_config.memaccess_in_config.has_coverage               = 0; // if the
//       // LC3-level instruction coverage lives in decode_in / imem instead

// ---- Nothing else to call ----------------------------------------------------
//   mem_access_model() is a pure function with no static state, so unlike
//   controller_model() there is no "only one caller" rule and no start-up step to
//   take. The memaccess environment needs no priming and no ordering with the other
//   stage environments.
