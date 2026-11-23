interface decode_out_monitor_bfm (
    decode_out_if bus
);
  decode_out_pkg::decode_out_monitor proxy;
  bit                                started = 0;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "LC3 invalid monitor startup");
    started = 1;
    forever begin
      @(bus.monitor_cb);
      if (bus.monitor_cb.reset === 0 && bus.monitor_cb.enable_decode === 1)
        proxy.notify_transaction(bus.monitor_cb.IR, bus.monitor_cb.npc_out, bus.monitor_cb.E_Control,
                                 bus.monitor_cb.W_Control, bus.monitor_cb.Mem_Control);
    end
  endtask
endinterface
