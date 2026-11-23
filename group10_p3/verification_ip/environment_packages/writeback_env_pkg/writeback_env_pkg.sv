package writeback_env_pkg;
  timeunit 1ns; timeprecision 1ps;
  import uvm_pkg::*;
  import lc3_prediction_pkg::*;
  import writeback_in_pkg::*;
  import writeback_out_pkg::*;
  `include "uvm_macros.svh"
  `include "src/writeback_env_configuration.svh"
  `include "src/writeback_expected_transaction.svh"
  `include "src/writeback_predictor.svh"
  `include "src/writeback_scoreboard.svh"
  `include "src/writeback_environment.svh"
endpackage
