interface decode_out_if (
    input wire        clock,
    input wire        reset,
    inout tri         enable_decode,
    inout tri  [15:0] IR,
    inout tri  [15:0] npc_out,
    inout tri  [ 5:0] E_Control,
    inout tri  [ 1:0] W_Control,
    inout tri         Mem_Control
);
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input reset;
    input enable_decode;
    input #0 IR;
    input #0 npc_out;
    input #0 E_Control;
    input #0 W_Control;
    input #0 Mem_Control;
  endclocking
endinterface
