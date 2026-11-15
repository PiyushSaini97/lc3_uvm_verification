// execute_in_pkg
// Interface package for the INPUTS of the LC3 Execute stage.
//   ACTIVE  (execute block bench): driver BFM drives the 12 inputs
//   PASSIVE (LC3 bench):           monitor only, the LC3 pipeline drives the inputs
package execute_in_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "src/execute_in_transaction.svh"
  `include "src/execute_in_sequencer.svh"
  `include "src/execute_in_configuration.svh"
  `include "src/execute_in_driver.svh"
  `include "src/execute_in_monitor.svh"
  `include "src/execute_in_coverage.svh"
  `include "src/execute_in_agent.svh"
  `include "src/execute_in_sequence_base.svh"
  `include "src/execute_in_random_sequence.svh"
  `include "src/execute_in_bypass_sequence.svh"
  `include "src/execute_in_alu_sequence.svh"
  `include "src/execute_in_offset_sequence.svh"
endpackage : execute_in_pkg
