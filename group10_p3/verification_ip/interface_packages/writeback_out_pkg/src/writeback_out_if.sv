interface writeback_out_if (
    input wire        clock,
    input wire        reset,
    inout tri  [15:0] vsr1,
    inout tri  [15:0] vsr2,
    inout tri  [ 2:0] psr
);
  timeunit 1ns; timeprecision 1ps;
  // Read immediately before the rising edge, before DUT NBA updates.
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input reset, vsr1, vsr2, psr;
  endclocking
endinterface
