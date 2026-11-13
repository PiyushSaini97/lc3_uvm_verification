// memaccess_in_transaction
// One transaction = one clock cycle's worth of MemAccess inputs.
//
// Fields are 4-state `logic` (P2 used `bit`) so that X/Z on an internal LC3 net is
// visible in the transcript and transaction viewer instead of silently becoming 0.
// The predictor converts to 2-state when it calls mem_access_model().
class memaccess_in_transaction extends uvm_sequence_item;
  `uvm_object_utils(memaccess_in_transaction)

  logic [1:0]  mem_state;
  logic        M_Control;
  logic [15:0] M_Data;
  logic [15:0] M_Addr;
  logic [15:0] Data_dout;

  // Cycle index since reset (assigned by the monitor). Used by the scoreboard to
  // prove the input and output streams stay aligned cycle-for-cycle.
  int unsigned cycle;

  int  transaction_view_h;
  time start_time, end_time;

  function new(string name = "memaccess_in_transaction");
    super.new(name);
  endfunction

  // mem_state names, for readable transcripts. The encoding is the one
  // mem_access_model() branches on.
  function string state_name();
    case (mem_state)
      2'd0    : return "RD_DIRECT";    // read, address from M_Addr or Data_dout
      2'd1    : return "RD_INDIRECT";  // first read of LDI/STI, address from M_Addr
      2'd2    : return "WRITE";        // store
      2'd3    : return "IDLE";         // no memory access; outputs tri-stated
      default : return "X";
    endcase
  endfunction

  function bit has_unknown();
    return $isunknown({mem_state, M_Control, M_Data, M_Addr, Data_dout});
  endfunction

  virtual function string convert2string();
    return $sformatf("cycle=%0d mem_state=%0d(%s) M_Control=%b M_Data=0x%4h M_Addr=0x%4h Data_dout=0x%4h",
                     cycle, mem_state, state_name(), M_Control, M_Data, M_Addr, Data_dout);
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("cycle",     cycle,     32, UVM_DEC);
    printer.print_field("mem_state", mem_state, 2,  UVM_DEC);
    printer.print_field("M_Control", M_Control, 1,  UVM_BIN);
    printer.print_field("M_Data",    M_Data,    16, UVM_HEX);
    printer.print_field("M_Addr",    M_Addr,    16, UVM_HEX);
    printer.print_field("Data_dout", Data_dout, 16, UVM_HEX);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    memaccess_in_transaction rhs_;
    if (!$cast(rhs_, rhs)) `uvm_fatal("CAST", "do_copy: argument is not a memaccess_in_transaction")
    super.do_copy(rhs);
    mem_state = rhs_.mem_state;
    M_Control = rhs_.M_Control;
    M_Data    = rhs_.M_Data;
    M_Addr    = rhs_.M_Addr;
    Data_dout = rhs_.Data_dout;
    cycle     = rhs_.cycle;
  endfunction

  // 4-state (===) comparison so X never compares equal to 0 or 1.
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    memaccess_in_transaction rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return super.do_compare(rhs, comparer) &&
           mem_state === rhs_.mem_state    &&
           M_Control === rhs_.M_Control    &&
           M_Data    === rhs_.M_Data       &&
           M_Addr    === rhs_.M_Addr       &&
           Data_dout === rhs_.Data_dout;
  endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
    transaction_view_h = $begin_transaction(transaction_viewing_stream_h, "memaccess_in_transaction", start_time);
    $add_attribute(transaction_view_h, cycle,     "cycle");
    $add_attribute(transaction_view_h, mem_state, "mem_state");
    $add_attribute(transaction_view_h, M_Control, "M_Control");
    $add_attribute(transaction_view_h, M_Data,    "M_Data");
    $add_attribute(transaction_view_h, M_Addr,    "M_Addr");
    $add_attribute(transaction_view_h, Data_dout, "Data_dout");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction
endclass : memaccess_in_transaction
