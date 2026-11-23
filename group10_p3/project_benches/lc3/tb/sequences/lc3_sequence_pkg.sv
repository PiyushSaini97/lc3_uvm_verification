// lc3_sequence_pkg
// Stimulus for the LC3 top-level bench. At LC3 level a test controls only
// (1) the words instruction memory returns, (2) data-memory contents and
// (3) data-memory latency. The responders themselves live in the agents
// (imem_responder_sequence, dmem_responder_sequence); this package adds what a
// test selects with factory overrides.
//
//   lc3_isa                         encoders for the 12 implemented instructions
//   lc3_program_generator           coverage-directed instruction stream (snippets)
//   lc3_program_responder_sequence  imem responder fed by the generator
//   imem_alu_transaction            ADD/AND/NOT only
//   imem_mem_transaction            LD/LDI/LEA/LDR/ST/STI/STR only
//   imem_ctrl_transaction           BR/JMP heavy, with condition-code setters
//   imem_sweep_transaction          every legal encoding once (37448 words)
//   lc3_vseq                        virtual sequence a test starts
package lc3_sequence_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import imem_pkg::*;
  import dmem_pkg::*;

  `include "src/lc3_isa.svh"
  `include "src/lc3_program_generator.svh"
  `include "src/lc3_program_responder_sequence.svh"
  `include "src/imem_alu_transaction.svh"
  `include "src/imem_mem_transaction.svh"
  `include "src/imem_ctrl_transaction.svh"
  `include "src/imem_sweep_transaction.svh"
  `include "src/lc3_vseq.svh"
endpackage : lc3_sequence_pkg
