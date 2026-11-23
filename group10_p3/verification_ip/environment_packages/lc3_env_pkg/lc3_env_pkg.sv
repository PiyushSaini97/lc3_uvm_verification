package lc3_env_pkg;
  import uvm_pkg::*;
  import fetch_env_pkg::*;
  import decode_env_pkg::*;
  import execute_env_pkg::*;
  import memaccess_env_pkg::*;
  import control_env_pkg::*;
  import writeback_env_pkg::*;
  import imem_pkg::*;
  import dmem_pkg::*;
  `include "uvm_macros.svh"
  `include "src/lc3_env_configuration.svh"
  `include "src/lc3_predictor.svh"
  `include "src/lc3_scoreboard.svh"
  `include "src/lc3_environment.svh"
endpackage
