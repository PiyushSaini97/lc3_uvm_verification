// memaccess_env_pkg
// Environment for the LC3 MemAccess block: two agents, a predictor driven by the
// course-provided mem_access_model(), and an in-order scoreboard.
package memaccess_env_pkg;
  import uvm_pkg::*;
  import memaccess_in_pkg::*;
  import memaccess_out_pkg::*;
  import lc3_prediction_pkg::*;
  `include "uvm_macros.svh"

  `include "src/memaccess_env_configuration.svh"
  `include "src/memaccess_predictor.svh"
  `include "src/memaccess_scoreboard.svh"
  `include "src/memaccess_environment.svh"
endpackage : memaccess_env_pkg
