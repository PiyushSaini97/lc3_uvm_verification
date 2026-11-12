// control_in_if
// Signal bundle for the controller's inputs (LC3 Design Spec, CONTROLLER section).
//
// `inout tri` ports, same style as P2's decode_in_if, so one interface serves both
// benches:
//   * control block bench: control_in_driver_bfm drives these nets (ACTIVE agent)
//   * LC3 top bench:       ports tie to LC3 nets by hierarchical reference
//                          (e.g. .IR(DUT.IR)) and the agent is PASSIVE
interface control_in_if (
  input  wire        clock,
  input  wire        reset,
  inout  tri         complete_data,   // from data memory: data access finished
  inout  tri         complete_instr,  // from instruction memory: instruction valid
  inout  tri  [15:0] IR,              // from Decode    (instruction at decode output)
  inout  tri  [2:0]  psr,             // from Writeback (N,Z,P of last RF write)
  inout  tri  [15:0] IR_Exec,         // from Execute   (instruction at execute output)
  inout  tri  [15:0] IMem_dout,       // from IMem      (Instr_dout in the RTL)
  inout  tri  [2:0]  NZP              // from Execute   (branch condition bits)
);
endinterface : control_in_if
