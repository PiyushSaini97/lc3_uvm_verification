// control_out_transaction
// One transaction = one clock cycle's worth of controller outputs.
//
// 4-state fields + 4-state (===) compare: the predictor produces clean 0/1 values,
// so an X or Z on an enable coming out of the RTL becomes a scoreboard mismatch
// instead of being quietly converted to 0 and "passing".
class control_out_transaction extends uvm_sequence_item;
  `uvm_object_utils(control_out_transaction)

  logic       enable_updatePC;
  logic       enable_fetch;
  logic       enable_decode;
  logic       enable_execute;
  logic       enable_writeback;
  logic       bypass_alu_1;
  logic       bypass_alu_2;
  logic       bypass_mem_1;
  logic       bypass_mem_2;
  logic [1:0] mem_state;
  logic       br_taken;

  int unsigned cycle;   // not part of compare; used for alignment checks/debug

  int  transaction_view_h;
  time start_time, end_time;

  function new(string name = "control_out_transaction");
    super.new(name);
  endfunction

  // Compact enable vector {updatePC, fetch, decode, execute, writeback}.
  function logic [4:0] enables();
    return {enable_updatePC, enable_fetch, enable_decode, enable_execute, enable_writeback};
  endfunction

  // Compact bypass vector {alu_1, alu_2, mem_1, mem_2}.
  function logic [3:0] bypasses();
    return {bypass_alu_1, bypass_alu_2, bypass_mem_1, bypass_mem_2};
  endfunction

  virtual function string convert2string();
    return $sformatf({"cycle=%0d en{updPC,fet,dec,exe,wb}=5'b%5b ",
                      "bypass{alu1,alu2,mem1,mem2}=4'b%4b mem_state=%0d br_taken=%b"},
                     cycle, enables(), bypasses(), mem_state, br_taken);
  endfunction

  // Lists only the fields that differ -> mismatch messages point straight at the bug.
  function string diff_string(control_out_transaction rhs);
    string s = "";
    if (enable_updatePC  !== rhs.enable_updatePC)  s = {s, $sformatf(" enable_updatePC(exp=%b act=%b)",  enable_updatePC,  rhs.enable_updatePC)};
    if (enable_fetch     !== rhs.enable_fetch)     s = {s, $sformatf(" enable_fetch(exp=%b act=%b)",     enable_fetch,     rhs.enable_fetch)};
    if (enable_decode    !== rhs.enable_decode)    s = {s, $sformatf(" enable_decode(exp=%b act=%b)",    enable_decode,    rhs.enable_decode)};
    if (enable_execute   !== rhs.enable_execute)   s = {s, $sformatf(" enable_execute(exp=%b act=%b)",   enable_execute,   rhs.enable_execute)};
    if (enable_writeback !== rhs.enable_writeback) s = {s, $sformatf(" enable_writeback(exp=%b act=%b)", enable_writeback, rhs.enable_writeback)};
    if (bypass_alu_1     !== rhs.bypass_alu_1)     s = {s, $sformatf(" bypass_alu_1(exp=%b act=%b)",     bypass_alu_1,     rhs.bypass_alu_1)};
    if (bypass_alu_2     !== rhs.bypass_alu_2)     s = {s, $sformatf(" bypass_alu_2(exp=%b act=%b)",     bypass_alu_2,     rhs.bypass_alu_2)};
    if (bypass_mem_1     !== rhs.bypass_mem_1)     s = {s, $sformatf(" bypass_mem_1(exp=%b act=%b)",     bypass_mem_1,     rhs.bypass_mem_1)};
    if (bypass_mem_2     !== rhs.bypass_mem_2)     s = {s, $sformatf(" bypass_mem_2(exp=%b act=%b)",     bypass_mem_2,     rhs.bypass_mem_2)};
    if (mem_state        !== rhs.mem_state)        s = {s, $sformatf(" mem_state(exp=%0d act=%0d)",      mem_state,        rhs.mem_state)};
    if (br_taken         !== rhs.br_taken)         s = {s, $sformatf(" br_taken(exp=%b act=%b)",         br_taken,         rhs.br_taken)};
    return s;
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("cycle",            cycle,            32, UVM_DEC);
    printer.print_field("enable_updatePC",  enable_updatePC,  1,  UVM_BIN);
    printer.print_field("enable_fetch",     enable_fetch,     1,  UVM_BIN);
    printer.print_field("enable_decode",    enable_decode,    1,  UVM_BIN);
    printer.print_field("enable_execute",   enable_execute,   1,  UVM_BIN);
    printer.print_field("enable_writeback", enable_writeback, 1,  UVM_BIN);
    printer.print_field("bypass_alu_1",     bypass_alu_1,     1,  UVM_BIN);
    printer.print_field("bypass_alu_2",     bypass_alu_2,     1,  UVM_BIN);
    printer.print_field("bypass_mem_1",     bypass_mem_1,     1,  UVM_BIN);
    printer.print_field("bypass_mem_2",     bypass_mem_2,     1,  UVM_BIN);
    printer.print_field("mem_state",        mem_state,        2,  UVM_DEC);
    printer.print_field("br_taken",         br_taken,         1,  UVM_BIN);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    control_out_transaction rhs_;
    if (!$cast(rhs_, rhs)) `uvm_fatal("CAST", "do_copy: argument is not a control_out_transaction")
    super.do_copy(rhs);
    enable_updatePC  = rhs_.enable_updatePC;
    enable_fetch     = rhs_.enable_fetch;
    enable_decode    = rhs_.enable_decode;
    enable_execute   = rhs_.enable_execute;
    enable_writeback = rhs_.enable_writeback;
    bypass_alu_1     = rhs_.bypass_alu_1;
    bypass_alu_2     = rhs_.bypass_alu_2;
    bypass_mem_1     = rhs_.bypass_mem_1;
    bypass_mem_2     = rhs_.bypass_mem_2;
    mem_state        = rhs_.mem_state;
    br_taken         = rhs_.br_taken;
    cycle            = rhs_.cycle;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    control_out_transaction rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return super.do_compare(rhs, comparer)            &&
           enable_updatePC  === rhs_.enable_updatePC  &&
           enable_fetch     === rhs_.enable_fetch     &&
           enable_decode    === rhs_.enable_decode    &&
           enable_execute   === rhs_.enable_execute   &&
           enable_writeback === rhs_.enable_writeback &&
           bypass_alu_1     === rhs_.bypass_alu_1     &&
           bypass_alu_2     === rhs_.bypass_alu_2     &&
           bypass_mem_1     === rhs_.bypass_mem_1     &&
           bypass_mem_2     === rhs_.bypass_mem_2     &&
           mem_state        === rhs_.mem_state        &&
           br_taken         === rhs_.br_taken;
  endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
    transaction_view_h = $begin_transaction(transaction_viewing_stream_h, "control_out_transaction", start_time);
    $add_attribute(transaction_view_h, cycle,            "cycle");
    $add_attribute(transaction_view_h, enable_updatePC,  "enable_updatePC");
    $add_attribute(transaction_view_h, enable_fetch,     "enable_fetch");
    $add_attribute(transaction_view_h, enable_decode,    "enable_decode");
    $add_attribute(transaction_view_h, enable_execute,   "enable_execute");
    $add_attribute(transaction_view_h, enable_writeback, "enable_writeback");
    $add_attribute(transaction_view_h, bypass_alu_1,     "bypass_alu_1");
    $add_attribute(transaction_view_h, bypass_alu_2,     "bypass_alu_2");
    $add_attribute(transaction_view_h, bypass_mem_1,     "bypass_mem_1");
    $add_attribute(transaction_view_h, bypass_mem_2,     "bypass_mem_2");
    $add_attribute(transaction_view_h, mem_state,        "mem_state");
    $add_attribute(transaction_view_h, br_taken,         "br_taken");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction
endclass : control_out_transaction
