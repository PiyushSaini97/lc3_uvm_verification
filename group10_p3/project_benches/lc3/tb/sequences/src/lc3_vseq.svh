// lc3_vseq
// Virtual sequence: the single entry point a test starts. It creates the two
// memory responders through the factory, runs them in parallel on their
// sequencers and returns once `num_instructions` fetches have been answered
// (prologue included). Tests choose the stimulus with factory overrides:
//   * imem_responder_sequence -> lc3_program_responder_sequence (snippet generator)
//   * imem_transaction        -> imem_alu/mem/ctrl/sweep_transaction (instruction mix)
// The responders keep answering after body() returns, so the pipeline can drain;
// they end with the run phase.
class lc3_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(lc3_vseq)

  imem_sequencer          imem_sqr;
  dmem_sequencer          dmem_sqr;

  int unsigned            num_instructions = 5000;

  imem_responder_sequence imem_seq;
  dmem_responder_sequence dmem_seq;

  function new(string name = "lc3_vseq");
    super.new(name);
  endfunction

  virtual task body();
    lc3_program_responder_sequence program_seq;
    if (imem_sqr == null || dmem_sqr == null)
      `uvm_fatal(get_type_name(), "imem_sqr and dmem_sqr must be set before start()");

    imem_seq = imem_responder_sequence::type_id::create("imem_seq");
    dmem_seq = dmem_responder_sequence::type_id::create("dmem_seq");
    `uvm_info(get_type_name(), $sformatf(
              "imem responder %s, data responder %s, %0d fetches",
              imem_seq.get_type_name(),
              dmem_seq.get_type_name(),
              num_instructions
              ), UVM_LOW);
    fork
      imem_seq.start(imem_sqr);
      dmem_seq.start(dmem_sqr);
    join_none

    // responses is incremented when the IMEM driver completes a fetch (falling edge).
    wait (imem_seq.responses >= num_instructions);
    if ($cast(program_seq, imem_seq) && program_seq.gen != null)
      `uvm_info(get_type_name(), {"program: ", program_seq.gen.summary()}, UVM_LOW);
  endtask
endclass : lc3_vseq
