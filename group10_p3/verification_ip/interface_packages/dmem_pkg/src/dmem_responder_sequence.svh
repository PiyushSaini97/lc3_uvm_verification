// dmem_responder_sequence
// Data-memory responder. An address returns random data on its first read and
// remembers every store. Two biases aim at coverage:
//
//   * Contents favour 0000, 0001, 7FFF, 8000, FFFE and FFFF (about 60%). Loaded
//     values feed vsr/aluout/psr corners, and in LDI/STI the word read first is the
//     pointer, so its corners give Data_addr 0000 and FFFF.
//   * Latency covers the whole legal range 1-3 (dmem_transaction's delay_c), so
//     every memory state is seen both waiting and completing.
//
// Contents and latency come from randomizing a factory-created dmem_transaction,
// so a test can replace either with a type override.
class dmem_responder_sequence extends uvm_sequence #(dmem_transaction);
  `uvm_object_utils(dmem_responder_sequence)
  `uvm_declare_p_sequencer(dmem_sequencer)

  bit          [15:0] memory[bit [15:0]];
  int unsigned        responses;

  function new(string name = "dmem_responder_sequence");
    super.new(name);
  endfunction

  protected virtual function void fill(dmem_transaction request, dmem_transaction response);
    if (!response.randomize() with {
          latency dist {
            1 := 5,
            2 := 3,
            3 := 2
          };
          data dist {
            16'h0000 := 1,
            16'h0001 := 1,
            16'h7fff := 1,
            16'h8000 := 1,
            16'hfffe := 1,
            16'hffff := 1,
            [16'h0002 : 16'h7ffe] :/ 2,
            [16'h8001 : 16'hfffd] :/ 2
          };
        })
      `uvm_fatal("DMEM_RANDOM", "dmem response randomization failed");
  endfunction

  virtual task body();
    dmem_transaction request, response;
    forever begin
      p_sequencer.requests.get(request);
      response = dmem_transaction::type_id::create("response");
      start_item(response);
      fill(request, response);
      response.address = request.address;
      response.read    = request.read;
      if (!memory.exists(request.address)) memory[request.address] = response.data;
      response.data = memory[request.address];
      finish_item(response);
      if (request.read === 1'b0 && !response.aborted) memory[request.address] = request.write_data;
      responses++;
    end
  endtask
endclass : dmem_responder_sequence
