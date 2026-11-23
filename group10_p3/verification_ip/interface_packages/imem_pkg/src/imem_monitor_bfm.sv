interface imem_monitor_bfm (
    imem_if bus
);
  imem_pkg::imem_monitor proxy;
  bit started = 0, pending = 0;
  logic [15:0] saved_address, saved_write_data;
  logic saved_read;
  task start_monitoring();
    if (started || proxy == null) $fatal(1, "Memory monitor invalid startup");
    started = 1;
    fork
      forever begin
        @(bus.request_cb);
        if (bus.request_cb.reset !== 0) pending = 0;
        else if (bus.request_cb.request === 1) begin
          if (pending) $fatal(1, "IMEM request arrived before previous response");
          if ($isunknown({bus.request_cb.address, bus.request_cb.read}))
            $fatal(1, "Unknown monitored IMEM request");
          saved_address    = bus.request_cb.address;
          saved_read       = bus.request_cb.read;
          saved_write_data = bus.request_cb.write_data;
          pending          = 1;
        end
      end
      forever begin
        @(bus.monitor_cb);
        if (bus.monitor_cb.reset !== 0) pending = 0;
        else if (pending) begin
          if (bus.monitor_cb.complete !== 1) $fatal(1, "Missing synchronous IMEM response");
          if ($isunknown(bus.monitor_cb.read_data)) $fatal(1, "Unknown IMEM response data");
          proxy.notify_transaction(saved_address, saved_read, bus.monitor_cb.read_data);
          pending = 0;
        end
        // A held complete is valid, but is not a new memory transaction.
      end
    join
  endtask
endinterface
