// control_out_pkg
// Passive (monitor-only) interface package for the OUTPUTS of the LC3 Controller.
package control_out_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "src/control_out_transaction.svh"
  `include "src/control_out_sequencer.svh"
  `include "src/control_out_configuration.svh"
  `include "src/control_out_monitor.svh"
  `include "src/control_out_coverage.svh"
  `include "src/control_out_agent.svh"
endpackage : control_out_pkg
