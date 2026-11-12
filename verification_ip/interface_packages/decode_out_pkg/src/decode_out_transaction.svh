class decode_out_transaction extends uvm_sequence_item;
  `uvm_object_utils(decode_out_transaction)

  bit [15:0] IR;
  bit [15:0] npc_out;
  bit [5:0]  E_Control;
  bit [1:0]  W_Control;
  bit        Mem_Control;

  int  transaction_view_h;
  time start_time, end_time;

  function new(string name = "decode_out_transaction");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("IR=0x%4h npc_out=0x%4h E_Control=6'b%6b W_Control=%0d Mem_Control=%0b",
                     IR, npc_out, E_Control, W_Control, Mem_Control);
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("IR",          IR,          16, UVM_HEX);
    printer.print_field("npc_out",     npc_out,     16, UVM_HEX);
    printer.print_field("E_Control",   E_Control,   6,  UVM_BIN);
    printer.print_field("W_Control",   W_Control,   2,  UVM_DEC);
    printer.print_field("Mem_Control", Mem_Control, 1,  UVM_BIN);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    decode_out_transaction rhs_;
    if (!$cast(rhs_, rhs)) `uvm_fatal("CAST", "do_copy: argument is not a decode_out_transaction")
    super.do_copy(rhs);
    IR          = rhs_.IR;
    npc_out     = rhs_.npc_out;
    E_Control   = rhs_.E_Control;
    W_Control   = rhs_.W_Control;
    Mem_Control = rhs_.Mem_Control;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    decode_out_transaction rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return super.do_compare(rhs, comparer)  &&
           IR          == rhs_.IR          &&
           npc_out     == rhs_.npc_out     &&
           E_Control   == rhs_.E_Control   &&
           W_Control   == rhs_.W_Control   &&
           Mem_Control == rhs_.Mem_Control;
  endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
    transaction_view_h = $begin_transaction(transaction_viewing_stream_h, "decode_out_transaction", start_time);
    $add_attribute(transaction_view_h, IR,          "IR");
    $add_attribute(transaction_view_h, npc_out,     "npc_out");
    $add_attribute(transaction_view_h, E_Control,   "E_Control");
    $add_attribute(transaction_view_h, W_Control,   "W_Control");
    $add_attribute(transaction_view_h, Mem_Control, "Mem_Control");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction
endclass : decode_out_transaction
