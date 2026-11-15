// execute_env_pkg
// Environment for the LC3 Execute stage: two agents, a predictor driven by the
// course-provided execute_model(), and an in-order scoreboard.
package execute_env_pkg;
  import uvm_pkg::*;
  import execute_in_pkg::*;
  import execute_out_pkg::*;
  import lc3_prediction_pkg::*;
  `include "uvm_macros.svh"

  `include "src/execute_env_configuration.svh"
  `include "src/execute_predictor.svh"
  `include "src/execute_scoreboard.svh"
  `include "src/execute_environment.svh"
endpackage : execute_env_pkg
