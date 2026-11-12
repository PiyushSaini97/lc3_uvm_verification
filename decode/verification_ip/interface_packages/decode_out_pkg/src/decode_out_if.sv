interface decode_out_if (
  input  wire        clock,
  input  wire        reset,
  inout  tri         enable_decode,
  inout  tri  [15:0] IR,
  inout  tri  [15:0] npc_out,
  inout  tri  [5:0]  E_Control,
  inout  tri  [1:0]  W_Control,
  inout  tri         Mem_Control
);
endinterface : decode_out_if
