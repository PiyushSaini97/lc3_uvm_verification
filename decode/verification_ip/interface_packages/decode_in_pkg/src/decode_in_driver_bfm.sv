interface decode_in_driver_bfm (decode_in_if bus);

  tri clock_i;
  tri reset_i;
  assign clock_i = bus.clock;
  assign reset_i = bus.reset;

  reg        enable_decode_o = 1'b0;
  reg [15:0] dout_o          = 16'h0000;
  reg [15:0] npc_in_o        = 16'h0000;
  assign bus.enable_decode = enable_decode_o;
  assign bus.dout          = dout_o;
  assign bus.npc_in        = npc_in_o;

  task wait_for_reset();
    @(posedge clock_i);
    while (reset_i === 1'b1) @(posedge clock_i);
  endtask

  task drive(input bit [15:0] dout, input bit [15:0] npc_in);
    @(posedge clock_i);
    dout_o          <= dout;
    npc_in_o        <= npc_in;
    enable_decode_o <= 1'b1;
    @(posedge clock_i);
    enable_decode_o <= 1'b0;
  endtask

endinterface : decode_in_driver_bfm
