class decode_in_random_sequence extends decode_in_sequence_base;
  `uvm_object_utils(decode_in_random_sequence)
  function new(string name = "decode_in_random_sequence");
    super.new(name);
  endfunction
  virtual task body();
    req = decode_in_transaction::type_id::create("req");
    start_item(req);
    if (!req.randomize())
      `uvm_fatal(get_type_name(), "decode_in_transaction randomize failed")
    finish_item(req);
  endtask
endclass : decode_in_random_sequence
