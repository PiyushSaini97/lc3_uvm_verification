// control_in_sequence_base
class control_in_sequence_base extends uvm_sequence #(control_in_stimulus);
  `uvm_object_utils(control_in_sequence_base)
  function new(string name = "control_in_sequence_base");
    super.new(name);
  endfunction
endclass : control_in_sequence_base
