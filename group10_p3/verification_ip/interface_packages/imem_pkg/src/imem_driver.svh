class imem_driver extends uvm_driver #(imem_transaction);
  `uvm_component_utils(imem_driver)
  imem_configuration                    configuration;
  imem_sequencer                        sequencer;
  uvm_analysis_port #(imem_transaction) expected_ap;
  int                                   completed;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_ap = new("expected_ap", this);
  endfunction
  task run_phase(uvm_phase phase);
    imem_transaction request, response;
    bit aborted;
    forever begin
      request = imem_transaction::type_id::create("request");
      configuration.driver_bfm.wait_request(request.address, request.read, request.write_data);
      sequencer.requests.put(request);
      seq_item_port.get_next_item(response);
      configuration.driver_bfm.respond(request.address, request.read, response.data, response.latency,
                                       aborted);
      response.aborted = aborted;
      if (!aborted) begin
        completed++;
        response.address = request.address;
        response.read    = request.read;
        if (request.read === 0) response.data = request.write_data;
        expected_ap.write(response);
      end
      seq_item_port.item_done();
    end
  endtask
endclass
