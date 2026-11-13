// memaccess_in_pkg
// Interface package for the INPUTS of the LC3 MemAccess block.
//   ACTIVE  (memaccess block bench): driver BFM drives mem_state, M_Control,
//                                    M_Data, M_Addr and Data_dout
//   PASSIVE (LC3 bench):             monitor only; the Controller and Execute drive
package memaccess_in_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "src/memaccess_in_transaction.svh"
  `include "src/memaccess_in_stimulus.svh"
  `include "src/memaccess_in_sequencer.svh"
  `include "src/memaccess_in_configuration.svh"
  `include "src/memaccess_in_driver.svh"
  `include "src/memaccess_in_monitor.svh"
  `include "src/memaccess_in_coverage.svh"
  `include "src/memaccess_in_agent.svh"
  `include "src/memaccess_in_sequence_base.svh"
  `include "src/memaccess_in_random_sequence.svh"
  `include "src/memaccess_in_fsm_sequence.svh"
endpackage : memaccess_in_pkg
