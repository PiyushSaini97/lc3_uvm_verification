// execute_out_if
// Signal bundle for the Execute stage outputs. enable_execute is included so the
// monitor can tell which cycle an output belongs to.
interface execute_out_if (
    input        clock,
    input        reset,
    inout        enable_execute,
    inout [15:0] aluout,
    inout [15:0] pcout,
    inout [ 1:0] W_Control_out,
    inout        Mem_Control_out,
    inout [ 2:0] dr,
    inout [ 2:0] sr1,
    inout [ 2:0] sr2,
    inout [15:0] IR_Exec,
    inout [ 2:0] NZP,
    inout [15:0] M_Data
);
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input reset;
    input enable_execute;
    input #0 aluout;
    input #0 pcout;
    input #0 W_Control_out;
    input #0 Mem_Control_out;
    input #0 dr;
    input sr1;
    input sr2;
    input #0 IR_Exec;
    input #0 NZP;
    input #0 M_Data;
  endclocking
endinterface
