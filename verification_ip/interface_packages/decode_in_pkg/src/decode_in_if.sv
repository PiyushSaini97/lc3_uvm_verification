interface decode_in_if (
  input  wire        clock,
  input  wire        reset,
  inout  tri         enable_decode,
  inout  tri  [15:0] dout,
  inout  tri  [15:0] npc_in
);
endinterface : decode_in_if
