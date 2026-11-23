// lc3_program_responder_sequence
// imem_responder_sequence whose words (after the prologue) come from
// lc3_program_generator's coverage-directed snippets instead of randomizing a
// transaction. test_top selects it with a factory override:
//   imem_responder_sequence::type_id::set_type_override(
//       lc3_program_responder_sequence::get_type());
class lc3_program_responder_sequence extends imem_responder_sequence;
  `uvm_object_utils(lc3_program_responder_sequence)

  lc3_program_generator gen;  // created (and +LC3_MIX applied) in body() if not supplied

  function new(string name = "lc3_program_responder_sequence");
    super.new(name);
  endfunction

  protected virtual function void fill(imem_transaction request, imem_transaction response);
    response.data   = gen.next();
    response.opcode = response.data[15:12];
  endfunction

  virtual task body();
    if (gen == null) begin
      gen = lc3_program_generator::type_id::create("gen");
      gen.apply_plusargs();
    end
    `uvm_info(get_type_name(), $sformatf("snippet weights %p", gen.weight), UVM_LOW);
    super.body();
  endtask
endclass : lc3_program_responder_sequence
