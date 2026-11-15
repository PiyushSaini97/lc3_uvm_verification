// execute_in_sequence_base
// Common base: num_items transactions per run of the sequence.
class execute_in_sequence_base extends uvm_sequence #(execute_in_transaction);
  `uvm_object_utils(execute_in_sequence_base)

  int unsigned num_items = 100;

  function new(string name = "execute_in_sequence_base");
    super.new(name);
  endfunction
endclass : execute_in_sequence_base
