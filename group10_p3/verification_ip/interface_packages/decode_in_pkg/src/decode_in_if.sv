interface decode_in_if (
    input wire        clock,
    input wire        reset,
    inout tri         enable_decode,
    inout tri  [15:0] dout,
    inout tri  [15:0] npc_in
);
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input reset;
    input enable_decode;
    input dout;
    input npc_in;
  endclocking
endinterface
