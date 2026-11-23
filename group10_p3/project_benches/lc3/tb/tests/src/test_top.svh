// test_top - default LC3 test: coverage-directed snippet stream
// Replaces the instruction responder with lc3_program_responder_sequence, which
// emits producer/consumer hazards, psr-setter + branch pairs, corner constants,
// jumps to corner addresses and indirect accesses (lc3_program_generator).
//   +LC3_MIX=<w0,...,w6>  snippet weights RANDOM,HAZARD,BRANCH,CONST,JUMP,MEM_CORNER,INDIRECT
//                         (default 30,25,15,8,6,8,8)
class test_top extends lc3_base_test;
  `uvm_component_utils(test_top)
  function new(string name = "test_top", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  protected virtual function void set_overrides();
    imem_responder_sequence::type_id::set_type_override(lc3_program_responder_sequence::get_type());
  endfunction
endclass : test_top
