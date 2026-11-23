// control_env_pkg
// Environment for the LC3 Controller: two passive agents, a predictor driven by the
// course-provided controller_model(), and an in-order scoreboard.
package control_env_pkg;
  import uvm_pkg::*;
  import control_in_pkg::*;
  import control_out_pkg::*;
  import lc3_prediction_pkg::*;
  `include "uvm_macros.svh"

  `include "src/control_env_configuration.svh"
  `include "src/control_predictor.svh"
  `include "src/control_scoreboard.svh"
  `include "src/control_environment.svh"
endpackage : control_env_pkg
