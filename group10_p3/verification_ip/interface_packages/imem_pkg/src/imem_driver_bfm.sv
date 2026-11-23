interface imem_driver_bfm (
    imem_if bus
);
  logic [15:0] data_out = 16'h5020;
  logic        ack = 1;  // Startup word ready; first decode is disabled by reset/startup.
  logic [15:0] response_address = 16'h3000;
  assign bus.read_data = data_out;
  // PC belongs to FE1; this response belongs to the preceding FE2 request.
  // A PC change is not a reason to invalidate that completed response.
  assign bus.complete  = ack;
  task wait_request(output logic [15:0] address, output logic read, output logic [15:0] data);
    do @(bus.request_cb); while (bus.request_cb.reset !== 0 || bus.request_cb.request !== 1);
    if ($isunknown({bus.request_cb.address, bus.request_cb.read})) $fatal(1, "Unknown IMEM request");
    if (bus.request_cb.read !== 1) $fatal(1, "Instruction memory expects read requests");
    address = bus.request_cb.address;
    read    = bus.request_cb.read;
    data    = bus.request_cb.write_data;
  endtask
  task respond(input logic [15:0] address, input logic read, input bit [15:0] data,
               input int unsigned latency, output bit aborted);
    aborted = 0;
    // Establish the documented synchronous, no-additional-wait baseline first.
    // Nonzero instruction waits need separate protocol/model validation.
    if (latency != 0)
      $fatal(1, "IMEM extra wait states not validated: use lc3_fast_test for this timing diagnostic");
    @(negedge bus.clock);
    if (bus.reset !== 0) begin
      aborted = 1;
      ack     = 0;
      return;
    end
    response_address = address;
    data_out         = data;
    ack              = 1;
    // Return now to allow capture of the next rising-edge request. Data and
    // completion remain stable when no further fetch request is made.
  endtask
endinterface
