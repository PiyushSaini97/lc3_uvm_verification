// control_in_pkg
// Interface package for the INPUTS of the LC3 Controller.
//   ACTIVE  (control block bench): driver BFM emulates IMem/Decode/Execute/WB/DMem
//   PASSIVE (LC3 bench):           monitor only
package control_in_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "src/control_in_transaction.svh"
  `include "src/control_in_stimulus.svh"
  `include "src/control_in_sequencer.svh"
  `include "src/control_in_configuration.svh"
  `include "src/control_in_driver.svh"
  `include "src/control_in_monitor.svh"
  `include "src/control_in_coverage.svh"
  `include "src/control_in_agent.svh"
  `include "src/control_in_sequence_base.svh"
  `include "src/control_in_random_sequence.svh"
endpackage : control_in_pkg
