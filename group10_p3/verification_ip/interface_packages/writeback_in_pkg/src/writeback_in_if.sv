interface writeback_in_if (
    input wire        clock,
    input wire        reset,
    inout tri         enable_writeback,
    inout tri  [ 1:0] W_Control,
    inout tri  [15:0] aluout,
    inout tri  [15:0] npc,
    inout tri  [15:0] pcout,
    inout tri  [15:0] memout,
    inout tri  [ 2:0] sr1,
    inout tri  [ 2:0] sr2,
    inout tri  [ 2:0] dr
);
  timeunit 1ns; timeprecision 1ps;
  // Read immediately before the rising edge, before DUT NBA updates.
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input reset, enable_writeback, W_Control, aluout, npc, pcout, memout, sr1, sr2, dr;
  endclocking
endinterface
