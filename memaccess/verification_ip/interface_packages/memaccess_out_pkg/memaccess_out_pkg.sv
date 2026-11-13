// memaccess_out_pkg
// Passive (monitor-only) interface package for the OUTPUTS of the LC3 MemAccess
// block: Data_addr, Data_din, Data_rd and memout.
package memaccess_out_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "src/memaccess_out_transaction.svh"
  `include "src/memaccess_out_sequencer.svh"
  `include "src/memaccess_out_configuration.svh"
  `include "src/memaccess_out_monitor.svh"
  `include "src/memaccess_out_coverage.svh"
  `include "src/memaccess_out_agent.svh"
endpackage : memaccess_out_pkg
