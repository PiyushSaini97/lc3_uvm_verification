interface decode_in_monitor_bfm (
    decode_in_if bus
);
  decode_in_pkg::decode_in_monitor proxy;
  bit                              started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "LC3 invalid monitor startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      if (bus.monitor_cb.reset === 1'b0 && bus.monitor_cb.enable_decode === 1'b1)
        proxy.notify_transaction(bus.monitor_cb.dout, bus.monitor_cb.npc_in);
    end
  endtask
endinterface
