// memaccess_out_transaction
// One transaction = one clock cycle's worth of MemAccess outputs.
//
// 4-state fields + 4-state (===) compare. This matters more here than anywhere else
// in the LC3 bench: mem_access_model() drives the outputs to 'z' in the IDLE state
// (mem_state == 3), so Z is an EXPECTED value, not an error. A 2-state `bit` field
// would turn both the expected z and an actual x into 0 and call them equal.
class memaccess_out_transaction extends uvm_sequence_item;
  `uvm_object_utils(memaccess_out_transaction)

  logic [15:0] Data_addr;
  logic [15:0] Data_din;
  logic        Data_rd;
  logic [15:0] memout;

  int unsigned cycle;       // not part of compare; used for alignment checks/debug

  // Set by the predictor when the model's inputs for this cycle were not fully
  // defined, so its outputs are the function's X default rather than a statement
  // about the DUT. The scoreboard keeps the entry (so the two streams stay aligned
  // one-for-one) but does not compare it. See memaccess_predictor.
  bit dont_care;

  int  transaction_view_h;
  time start_time, end_time;

  function new(string name = "memaccess_out_transaction");
    super.new(name);
  endfunction

  // Classification helpers. Coverage samples these rather than the raw fields,
  // because a coverpoint bin cannot match an x or z value.
  //   0 = write (rd==0), 1 = read (rd==1), 2 = tri-stated (idle), 3 = unknown
  function bit [1:0] rd_class();
    if (Data_rd === 1'b0) return 2'd0;
    if (Data_rd === 1'b1) return 2'd1;
    if (Data_rd === 1'bz) return 2'd2;
    return 2'd3;
  endfunction

  //   0 = 0x0000, 1 = 0xFFFF, 2 = other defined, 3 = all z (idle), 4 = any x
  function bit [2:0] word_class(input logic [15:0] w);
    if (w === 16'hzzzz)  return 3'd3;
    if ($isunknown(w))   return 3'd4;
    if (w == 16'h0000)   return 3'd0;
    if (w == 16'hFFFF)   return 3'd1;
    return 3'd2;
  endfunction

  function bit [2:0] addr_class();   return word_class(Data_addr); endfunction
  function bit [2:0] din_class();    return word_class(Data_din);  endfunction
  function bit [2:0] memout_class(); return word_class(memout);    endfunction

  virtual function string convert2string();
    return $sformatf("cycle=%0d Data_addr=0x%4h Data_din=0x%4h Data_rd=%b memout=0x%4h%s",
                     cycle, Data_addr, Data_din, Data_rd, memout,
                     dont_care ? " [not compared: undefined inputs]" : "");
  endfunction

  // Names only the fields that differ, so a mismatch report points at one signal.
  function string diff_string(memaccess_out_transaction rhs);
    string s = "";
    if (Data_addr !== rhs.Data_addr) s = {s, $sformatf(" Data_addr(exp=0x%4h act=0x%4h)", Data_addr, rhs.Data_addr)};
    if (Data_din  !== rhs.Data_din)  s = {s, $sformatf(" Data_din(exp=0x%4h act=0x%4h)",  Data_din,  rhs.Data_din)};
    if (Data_rd   !== rhs.Data_rd)   s = {s, $sformatf(" Data_rd(exp=%b act=%b)",         Data_rd,   rhs.Data_rd)};
    if (memout    !== rhs.memout)    s = {s, $sformatf(" memout(exp=0x%4h act=0x%4h)",    memout,    rhs.memout)};
    return s;
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("cycle",     cycle,     32, UVM_DEC);
    printer.print_field("Data_addr", Data_addr, 16, UVM_HEX);
    printer.print_field("Data_din",  Data_din,  16, UVM_HEX);
    printer.print_field("Data_rd",   Data_rd,   1,  UVM_BIN);
    printer.print_field("memout",    memout,    16, UVM_HEX);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    memaccess_out_transaction rhs_;
    if (!$cast(rhs_, rhs)) `uvm_fatal("CAST", "do_copy: argument is not a memaccess_out_transaction")
    super.do_copy(rhs);
    Data_addr = rhs_.Data_addr;
    Data_din  = rhs_.Data_din;
    Data_rd   = rhs_.Data_rd;
    memout    = rhs_.memout;
    cycle     = rhs_.cycle;
    dont_care = rhs_.dont_care;
  endfunction

  // 4-state comparison: an expected 'z' matches only an actual 'z'.
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    memaccess_out_transaction rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return super.do_compare(rhs, comparer) &&
           Data_addr === rhs_.Data_addr    &&
           Data_din  === rhs_.Data_din     &&
           Data_rd   === rhs_.Data_rd      &&
           memout    === rhs_.memout;
  endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
    transaction_view_h = $begin_transaction(transaction_viewing_stream_h, "memaccess_out_transaction", start_time);
    $add_attribute(transaction_view_h, cycle,     "cycle");
    $add_attribute(transaction_view_h, Data_addr, "Data_addr");
    $add_attribute(transaction_view_h, Data_din,  "Data_din");
    $add_attribute(transaction_view_h, Data_rd,   "Data_rd");
    $add_attribute(transaction_view_h, memout,    "memout");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction
endclass : memaccess_out_transaction
