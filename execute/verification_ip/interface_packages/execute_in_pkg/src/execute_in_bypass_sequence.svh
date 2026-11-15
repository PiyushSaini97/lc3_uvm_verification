// execute_in_bypass_sequence
// Every item asserts at least one bypass. With realistic_bypass on, the solver can only
// pick instructions that use the bypassed operand, so this exercises all four bypass
// paths (alu and mem, operand 1 and 2) across the opcodes that use them.
class execute_in_bypass_sequence extends execute_in_sequence_base;
  `uvm_object_utils(execute_in_bypass_sequence)

  function new(string name = "execute_in_bypass_sequence");
    super.new(name);
  endfunction

  virtual task body();
    execute_in_transaction tr;
    for (int i = 0; i < num_items; i++) begin
      tr = execute_in_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize() with { bypass_alu_1 || bypass_alu_2 || bypass_mem_1 || bypass_mem_2; })
        `uvm_fatal("RAND", "randomize failed")
      finish_item(tr);
    end
  endtask
endclass : execute_in_bypass_sequence
