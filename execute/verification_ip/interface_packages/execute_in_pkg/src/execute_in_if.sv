// execute_in_if
// Signal bundle for the Execute stage inputs (LC3 Design Spec, EXECUTE section).
// `inout` ports, same style as P2's decode_in_if, so one interface serves both benches:
//   * execute block bench: execute_in_driver_bfm drives these nets (ACTIVE agent)
//   * LC3 top bench:       ports tie to LC3 nets by hierarchical reference
//                          (e.g. .IR(DUT.IR)) and the agent is PASSIVE
interface execute_in_if (
  input        clock,
  input        reset,
  inout        enable_execute,   // from Controller
  inout [5:0]  E_Control,        // from Decode
  inout [15:0] IR,               // from Decode
  inout [15:0] npc_in,           // from Decode (the Execute RTL port is called npc)
  inout        bypass_alu_1,     // from Controller
  inout        bypass_alu_2,
  inout        bypass_mem_1,
  inout        bypass_mem_2,
  inout [15:0] VSR1,             // from Writeback register file
  inout [15:0] VSR2,
  inout [15:0] Mem_Bypass_Val,   // from Mem Access (memout)
  inout [1:0]  W_Control_in,     // from Decode
  inout        Mem_Control_in    // from Decode
);
endinterface : execute_in_if
