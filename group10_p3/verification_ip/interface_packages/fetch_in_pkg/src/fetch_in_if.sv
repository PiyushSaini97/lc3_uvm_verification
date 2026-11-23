interface fetch_in_if (
    input wire        clock,
    input wire        reset,
    inout tri         enable_updatePC,
    inout tri         enable_fetch,
    inout tri         br_taken,
    inout tri  [15:0] taddr
);
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input reset;
    input enable_updatePC;
    input enable_fetch;
    input br_taken;
    input taddr;
  endclocking
endinterface
