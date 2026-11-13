// memaccess_in_random_sequence
// Unconstrained cycles: every field random, every clock. MemAccess is combinational
// with no state, so an arbitrary input vector is always a legal thing to ask of it,
// and this reaches input combinations the Controller would never produce.
//
// It covers the state and state x M_Control bins quickly, but NOT the FSM sequence
// bins, because a random walk almost never produces 3->1->0->3 in order. Those come
// from memaccess_in_fsm_sequence.
class memaccess_in_random_sequence extends memaccess_in_sequence_base;
  `uvm_object_utils(memaccess_in_random_sequence)

  function new(string name = "memaccess_in_random_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $sformatf("driving %0d random cycles", item_count), UVM_LOW)
    repeat (item_count) send_random();
  endtask
endclass : memaccess_in_random_sequence
