// execute_out_if
// Signal bundle for the Execute stage outputs. enable_execute is included so the
// monitor can tell which cycle an output belongs to.
interface execute_out_if (
  input        clock,
  input        reset,
  inout        enable_execute,
  inout [15:0] aluout,
  inout [15:0] pcout,
  inout [1:0]  W_Control_out,
  inout        Mem_Control_out,
  inout [2:0]  dr,
  inout [2:0]  sr1,
  inout [2:0]  sr2,
  inout [15:0] IR_Exec,
  inout [2:0]  NZP,
  inout [15:0] M_Data
);
endinterface : execute_out_if
