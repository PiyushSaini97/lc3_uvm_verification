// execute_out_pkg
// Interface package for the OUTPUTS of the LC3 Execute stage (monitor only).
package execute_out_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "src/execute_out_transaction.svh"
  `include "src/execute_out_configuration.svh"
  `include "src/execute_out_monitor.svh"
  `include "src/execute_out_coverage.svh"
  `include "src/execute_out_agent.svh"
endpackage : execute_out_pkg
