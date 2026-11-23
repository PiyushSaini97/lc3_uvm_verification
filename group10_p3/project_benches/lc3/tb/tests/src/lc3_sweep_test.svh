// lc3_sweep_test
// Every legal encoding of the 12 implemented instructions exactly once
// (imem_sweep_transaction, 37448 words), so imem_coverage's exhaustive crosses
// reach 100% in one run. Default length = prologue + one full lap.
// The order is a random permutation from the simulation seed.
class lc3_sweep_test extends lc3_base_test;
  `uvm_component_utils(lc3_sweep_test)
  function new(string name = "lc3_sweep_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  protected virtual function int unsigned default_instructions();
    return imem_responder_sequence::PROLOGUE_WORDS + imem_sweep_transaction::NUM_ENCODINGS;
  endfunction
  protected virtual function void set_overrides();
    imem_transaction::type_id::set_type_override(imem_sweep_transaction::get_type());
  endfunction
endclass : lc3_sweep_test
