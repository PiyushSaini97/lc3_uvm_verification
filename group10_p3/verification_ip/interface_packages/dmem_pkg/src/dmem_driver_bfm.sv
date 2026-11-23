interface dmem_driver_bfm (
    dmem_if bus
);
  logic [15:0] data_out = 16'h0000;
  logic        ack = 0;
  assign bus.read_data = data_out;
  assign bus.complete  = ack;
  task wait_request(output logic [15:0] address, output logic read, output logic [15:0] data);
    do @(bus.request_cb); while (bus.request_cb.reset !== 0 || bus.request_cb.request !== 1);
    if ($isunknown({bus.request_cb.address, bus.request_cb.read})) $fatal(1, "Unknown memory request");
    if (bus.request_cb.read === 0 && $isunknown(bus.request_cb.write_data))
      $fatal(1, "Unknown memory write data");
    address = bus.request_cb.address;
    read    = bus.request_cb.read;
    data    = bus.request_cb.write_data;
  endtask
  task respond(input logic [15:0] address, input logic read, input bit [15:0] data,
               input int unsigned latency, output bit aborted);
    aborted = 0;
    repeat (latency) begin
      @(negedge bus.clock);
      if (bus.reset !== 0) begin
        aborted = 1;
        ack     = 0;
        return;
      end
      if (bus.request !== 1 || bus.address !== address || bus.read !== read)
        $fatal(
            1,
            "DMEM request changed: saved_addr=%h current_addr=%h request=%b saved_read=%b current_read=%b reset=%b latency=%0d complete=%b read_data=%h",
            address,
            bus.address,
            bus.request,
            read,
            bus.read,
            bus.reset,
            latency,
            bus.complete,
            bus.read_data
        );
    end
    if (bus.reset !== 0) begin
      aborted = 1;
      return;
    end
    if (read === 1'b1) data_out = data;
    // Preserve the indirect-address pointer during writes.
    ack = 1;
    @(negedge bus.clock);
    ack = 0;
  endtask
endinterface
