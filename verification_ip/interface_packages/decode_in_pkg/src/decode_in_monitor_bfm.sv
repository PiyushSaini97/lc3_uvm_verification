interface decode_in_monitor_bfm (decode_in_if bus);

  decode_in_pkg::decode_in_monitor proxy;

  tri        clock_i;
  tri        reset_i;
  tri        enable_decode_i;
  tri [15:0] dout_i;
  tri [15:0] npc_in_i;
  assign clock_i         = bus.clock;
  assign reset_i         = bus.reset;
  assign enable_decode_i = bus.enable_decode;
  assign dout_i          = bus.dout;
  assign npc_in_i        = bus.npc_in;

  task start_monitoring();
    forever begin
      @(posedge clock_i);
      if (reset_i !== 1'b1 && enable_decode_i === 1'b1)
        proxy.notify_transaction(dout_i, npc_in_i);
    end
  endtask

endinterface : decode_in_monitor_bfm
