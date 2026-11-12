// control_in_transaction
// One transaction = one clock cycle's worth of controller inputs.
//
// Fields are 4-state `logic` (P2 used `bit`) so that X/Z on an internal LC3 net is
// visible in the transcript and transaction viewer instead of silently becoming 0.
// The predictor converts to 2-state when it calls controller_model().
class control_in_transaction extends uvm_sequence_item;
  `uvm_object_utils(control_in_transaction)

  logic        complete_data;
  logic        complete_instr;
  logic [15:0] IR;
  logic [2:0]  psr;
  logic [15:0] IR_Exec;
  logic [15:0] IMem_dout;
  logic [2:0]  NZP;

  // Cycle index since reset (assigned by the monitor). Used by the scoreboard to
  // prove the input and output streams stay aligned cycle-for-cycle.
  int unsigned cycle;

  // Set only on the one sample taken in the last reset cycle. The predictor uses it
  // to take controller_model()'s start-up step and does NOT predict or compare it.
  bit          prime;

  int  transaction_view_h;
  time start_time, end_time;

  function new(string name = "control_in_transaction");
    super.new(name);
  endfunction

  function bit has_unknown();
    return $isunknown({complete_data, complete_instr, IR, psr, IR_Exec, IMem_dout, NZP});
  endfunction

  virtual function string convert2string();
    return $sformatf({"%s complete_data=%b complete_instr=%b IR=0x%4h psr=3'b%3b ",
                      "IR_Exec=0x%4h IMem_dout=0x%4h NZP=3'b%3b"},
                     prime ? "prime(reset)" : $sformatf("cycle=%0d", cycle),
                     complete_data, complete_instr, IR, psr, IR_Exec, IMem_dout, NZP);
  endfunction

  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("cycle",          cycle,          32, UVM_DEC);
    printer.print_field("complete_data",  complete_data,  1,  UVM_BIN);
    printer.print_field("complete_instr", complete_instr, 1,  UVM_BIN);
    printer.print_field("IR",             IR,             16, UVM_HEX);
    printer.print_field("psr",            psr,            3,  UVM_BIN);
    printer.print_field("IR_Exec",        IR_Exec,        16, UVM_HEX);
    printer.print_field("IMem_dout",      IMem_dout,      16, UVM_HEX);
    printer.print_field("NZP",            NZP,            3,  UVM_BIN);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    control_in_transaction rhs_;
    if (!$cast(rhs_, rhs)) `uvm_fatal("CAST", "do_copy: argument is not a control_in_transaction")
    super.do_copy(rhs);
    complete_data  = rhs_.complete_data;
    complete_instr = rhs_.complete_instr;
    IR             = rhs_.IR;
    psr            = rhs_.psr;
    IR_Exec        = rhs_.IR_Exec;
    IMem_dout      = rhs_.IMem_dout;
    NZP            = rhs_.NZP;
    cycle          = rhs_.cycle;
    prime          = rhs_.prime;
  endfunction

  // 4-state (===) comparison so X never compares equal to 0 or 1.
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    control_in_transaction rhs_;
    if (!$cast(rhs_, rhs)) return 0;
    return super.do_compare(rhs, comparer)        &&
           complete_data  === rhs_.complete_data  &&
           complete_instr === rhs_.complete_instr &&
           IR             === rhs_.IR             &&
           psr            === rhs_.psr            &&
           IR_Exec        === rhs_.IR_Exec        &&
           IMem_dout      === rhs_.IMem_dout      &&
           NZP            === rhs_.NZP;
  endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
    transaction_view_h = $begin_transaction(transaction_viewing_stream_h, "control_in_transaction", start_time);
    $add_attribute(transaction_view_h, cycle,          "cycle");
    $add_attribute(transaction_view_h, complete_data,  "complete_data");
    $add_attribute(transaction_view_h, complete_instr, "complete_instr");
    $add_attribute(transaction_view_h, IR,             "IR");
    $add_attribute(transaction_view_h, psr,            "psr");
    $add_attribute(transaction_view_h, IR_Exec,        "IR_Exec");
    $add_attribute(transaction_view_h, IMem_dout,      "IMem_dout");
    $add_attribute(transaction_view_h, NZP,            "NZP");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction
endclass : control_in_transaction
