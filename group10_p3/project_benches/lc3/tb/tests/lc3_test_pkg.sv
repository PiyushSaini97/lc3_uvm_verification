// lc3_test_pkg
//   lc3_base_test   plain constrained-random instructions (no override)
//   test_top        coverage-directed snippet stream (default TESTNAME)
//   lc3_alu_test    ADD/AND/NOT only
//   lc3_mem_test    memory instructions only
//   lc3_ctrl_test   branch/jump heavy
//   lc3_sweep_test  every legal encoding once
package lc3_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import imem_pkg::*;
  import dmem_pkg::*;
  import lc3_env_pkg::*;
  import lc3_sequence_pkg::*;

  `include "src/lc3_base_test.svh"
  `include "src/test_top.svh"
  `include "src/lc3_alu_test.svh"
  `include "src/lc3_mem_test.svh"
  `include "src/lc3_ctrl_test.svh"
  `include "src/lc3_sweep_test.svh"
endpackage : lc3_test_pkg
