// imem_responder_sequence
// Instruction-memory responder. For every fetch request the CPU makes (the driver
// puts it in the sequencer's request FIFO) it returns one imem_transaction.
//
//   1. Prologue: AND Rk,Rk,#0 for R0..R7, then R0 again. Registers are X after
//      reset, and a JMP/LDR/STR through an X register makes the memory BFMs fatal.
//      The first word equals the driver BFM's preloaded startup word (0x5020);
//      R0 is cleared again in case that startup word is not executed.
//   2. After the prologue, fill() supplies the word. The default randomizes a
//      factory-created imem_transaction, so a test changes the instruction mix
//      with a type override and no new sequence:
//        imem_transaction::type_id::set_type_override(my_transaction::get_type());
//      Sequences that build the stream differently extend this class and
//      override fill().
//
// Latency is always 0: the IMEM driver BFM rejects instruction wait states.
class imem_responder_sequence extends uvm_sequence #(imem_transaction);
  `uvm_object_utils(imem_responder_sequence)
  `uvm_declare_p_sequencer(imem_sequencer)

  localparam int unsigned PROLOGUE_WORDS = 9;

  int unsigned         responses;  // fetches answered, prologue included
  bit                  use_prologue                                           = 1;

  protected bit [15:0] prologue                                          [$];

  function new(string name = "imem_responder_sequence");
    super.new(name);
  endfunction

  protected virtual function void build_prologue();
    prologue.delete();
    if (!use_prologue) return;
    for (int k = 0; k < 8; k++) prologue.push_back(16'(16'h5020 | (k << 9) | (k << 6)));
    prologue.push_back(16'h5020);
  endfunction

  // Supplies response.data for one fetch. request carries the fetch address.
  protected virtual function void fill(imem_transaction request, imem_transaction response);
    if (!response.randomize()) `uvm_fatal("IMEM_RANDOM", "imem response randomization failed");
  endfunction

  virtual task body();
    imem_transaction request, response;
    build_prologue();
    forever begin
      p_sequencer.requests.get(request);
      response = imem_transaction::type_id::create("response");
      start_item(response);
      if (prologue.size() != 0) begin
        response.data   = prologue.pop_front();
        response.opcode = response.data[15:12];
      end else fill(request, response);
      response.latency = 0;
      response.address = request.address;
      response.read    = request.read;
      `uvm_info(get_type_name(), $sformatf("fetch 0x%4h -> 0x%4h", request.address, response.data), UVM_HIGH);
      finish_item(response);
      responses++;
    end
  endtask
endclass : imem_responder_sequence
