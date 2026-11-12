interface decode_out_monitor_bfm (decode_out_if bus);

  decode_out_pkg::decode_out_monitor proxy;

  tri        clock_i;
  tri        reset_i;
  tri        enable_decode_i;
  tri [15:0] IR_i;
  tri [15:0] npc_out_i;
  tri [5:0]  E_Control_i;
  tri [1:0]  W_Control_i;
  tri        Mem_Control_i;
  assign clock_i         = bus.clock;
  assign reset_i         = bus.reset;
  assign enable_decode_i = bus.enable_decode;
  assign IR_i            = bus.IR;
  assign npc_out_i       = bus.npc_out;
  assign E_Control_i     = bus.E_Control;
  assign W_Control_i     = bus.W_Control;
  assign Mem_Control_i   = bus.Mem_Control;

  bit enable_q = 1'b0;

  task start_monitoring();
    forever begin
      @(posedge clock_i);
      if (enable_q && reset_i !== 1'b1)
        proxy.notify_transaction(IR_i, npc_out_i, E_Control_i, W_Control_i, Mem_Control_i);
      enable_q = (enable_decode_i === 1'b1) && (reset_i !== 1'b1);
    end
  endtask

endinterface : decode_out_monitor_bfm
