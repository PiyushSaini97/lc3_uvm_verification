// memaccess_in_if
// Signal bundle for the MemAccess block's inputs (LC3 Design Spec, MEM ACCESS section).
//
// `inout tri` ports, same style as control_in_if and P2's decode_in_if, so one
// interface serves both benches:
//   * memaccess block bench : memaccess_in_driver_bfm drives these nets (ACTIVE agent)
//   * LC3 top bench         : ports tie to LC3 nets by hierarchical reference
//                             (e.g. .M_Addr(DUT.pcout)) and the agent is PASSIVE
//
// Names are the RTL's (Mem_Access.v port list). mem_access_model() calls Data_dout
// "DMem_dout"; it is the same signal.
//
// NOTE: MemAccess itself has no clock and no reset port - it is purely
// combinational. clock and reset come from the surrounding system and are used only
// to decide WHEN the monitors sample. See the README, "One transaction per clock".
interface memaccess_in_if (
  input  wire        clock,
  input  wire        reset,
  inout  tri  [1:0]  mem_state,   // from Controller: memory FSM state
  inout  tri         M_Control,   // from Execute (RTL net Mem_Control_out): direct vs indirect
  inout  tri  [15:0] M_Data,      // from Execute: store data
  inout  tri  [15:0] M_Addr,      // from Execute (RTL net pcout): direct address
  inout  tri  [15:0] Data_dout    // from data memory: word read back
);
endinterface : memaccess_in_if
