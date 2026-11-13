// memaccess_in_sequence_base
// Common helpers for the memaccess_in sequences. One item = one clock cycle of
// MemAccess inputs, so a sequence is simply a list of cycles to drive.
class memaccess_in_sequence_base extends uvm_sequence #(memaccess_in_stimulus);
  `uvm_object_utils(memaccess_in_sequence_base)

  // Number of items (random sequence) or whole memory operations (FSM sequence).
  // Set by the test; see test_top.
  int unsigned item_count = 200;

  function new(string name = "memaccess_in_sequence_base");
    super.new(name);
  endfunction

  // One cycle with mem_state and M_Control pinned, data fields random.
  protected task send(input bit [1:0] st, input bit ctrl);
    memaccess_in_stimulus item;
    item = memaccess_in_stimulus::type_id::create("item");
    start_item(item);
    if (!item.randomize() with { mem_state == st; M_Control == ctrl; })
      `uvm_error(get_type_name(), $sformatf("randomize failed for mem_state=%0d M_Control=%b", st, ctrl))
    finish_item(item);
  endtask

  // One cycle with everything random.
  protected task send_random();
    memaccess_in_stimulus item;
    item = memaccess_in_stimulus::type_id::create("item");
    start_item(item);
    if (!item.randomize())
      `uvm_error(get_type_name(), "randomize failed")
    finish_item(item);
  endtask

  // Hold a state for `n` cycles, which is what a memory wait state looks like to
  // MemAccess: the Controller keeps mem_state until complete_data goes high.
  protected task hold(input bit [1:0] st, input bit ctrl, input int unsigned n);
    repeat (n) send(st, ctrl);
  endtask
endclass : memaccess_in_sequence_base
