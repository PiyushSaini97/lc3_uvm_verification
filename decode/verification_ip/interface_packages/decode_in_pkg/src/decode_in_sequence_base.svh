class decode_in_sequence_base extends uvm_sequence #(decode_in_transaction);
  `uvm_object_utils(decode_in_sequence_base)
  function new(string name = "decode_in_sequence_base");
    super.new(name);
  endfunction
endclass : decode_in_sequence_base
