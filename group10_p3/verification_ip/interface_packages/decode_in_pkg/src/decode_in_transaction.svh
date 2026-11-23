class decode_in_transaction extends uvm_sequence_item;
  `uvm_object_utils(decode_in_transaction)

  logic [15:0] dout;
  logic [15:0] npc_in;

  bit   [ 3:0] opcode;
  bit   [11:0] operand;

  int          transaction_view_h;
  time         start_time,         end_time;







  function new(string name = "decode_in_transaction");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("dout=0x%4h (opcode=4'b%4b) npc_in=0x%4h", dout, dout[15:12], npc_in);
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("dout", dout, 16, UVM_HEX);
    printer.print_field("npc_in", npc_in, 16, UVM_HEX);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    decode_in_transaction rhs_;
    if (!$cast(rhs_, rhs)) `uvm_fatal("CAST", "do_copy: argument is not a decode_in_transaction");
    super.do_copy(rhs);
    dout   = rhs_.dout;
    npc_in = rhs_.npc_in;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    decode_in_transaction rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return super.do_compare(rhs, comparer) && dout === rhs_.dout && npc_in === rhs_.npc_in;
  endfunction

`ifdef QUESTA_TRANSACTIONS
  virtual function void add_to_wave(int transaction_viewing_stream_h);
    transaction_view_h =
        $begin_transaction(transaction_viewing_stream_h, "decode_in_transaction", start_time);
    $add_attribute(transaction_view_h, dout, "dout");
    $add_attribute(transaction_view_h, npc_in, "npc_in");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction
`endif
endclass : decode_in_transaction
