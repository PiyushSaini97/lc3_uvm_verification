// execute_out_transaction
// What the Execute stage produced for one enabled cycle.
// 4-state fields and === compares: the predictor gives clean 0/1 values, so an X or Z
// coming out of the RTL shows up as a mismatch instead of being read as 0.
class execute_out_transaction extends uvm_sequence_item;
  `uvm_object_utils(execute_out_transaction)

  logic [15:0] aluout;
  logic [15:0] pcout;
  logic [1:0]  w_control_out;
  logic        mem_control_out;
  logic [2:0]  dr;
  logic [2:0]  sr1;
  logic [2:0]  sr2;
  logic [15:0] ir_exec;
  logic [2:0]  nzp;
  logic [15:0] m_data;

  int unsigned index;   // not compared; position in the enabled-cycle stream
  int          transaction_view_h;
  time         start_time, end_time;

  function new(string name = "execute_out_transaction");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("#%0d aluout:0x%h pcout:0x%h w_ctl:0x%h m_ctl:%b dr:%0d sr1:%0d sr2:%0d ir_exec:0x%h nzp:%03b m_data:0x%h",
                     index, aluout, pcout, w_control_out, mem_control_out, dr, sr1, sr2, ir_exec, nzp, m_data);
  endfunction

  // Lists only the fields that differ
  function string diff_string(execute_out_transaction rhs);
    string s;
    s = "";
    if (aluout          !== rhs.aluout)          s = {s, $sformatf(" aluout(exp=0x%h act=0x%h)",        aluout,          rhs.aluout)};
    if (pcout           !== rhs.pcout)           s = {s, $sformatf(" pcout(exp=0x%h act=0x%h)",         pcout,           rhs.pcout)};
    if (w_control_out   !== rhs.w_control_out)   s = {s, $sformatf(" w_control_out(exp=%0d act=%0d)",   w_control_out,   rhs.w_control_out)};
    if (mem_control_out !== rhs.mem_control_out) s = {s, $sformatf(" mem_control_out(exp=%b act=%b)",   mem_control_out, rhs.mem_control_out)};
    if (dr              !== rhs.dr)              s = {s, $sformatf(" dr(exp=%0d act=%0d)",              dr,              rhs.dr)};
    if (sr1             !== rhs.sr1)             s = {s, $sformatf(" sr1(exp=%0d act=%0d)",             sr1,             rhs.sr1)};
    if (sr2             !== rhs.sr2)             s = {s, $sformatf(" sr2(exp=%0d act=%0d)",             sr2,             rhs.sr2)};
    if (ir_exec         !== rhs.ir_exec)         s = {s, $sformatf(" ir_exec(exp=0x%h act=0x%h)",       ir_exec,         rhs.ir_exec)};
    if (nzp             !== rhs.nzp)             s = {s, $sformatf(" nzp(exp=%03b act=%03b)",           nzp,             rhs.nzp)};
    if (m_data          !== rhs.m_data)          s = {s, $sformatf(" m_data(exp=0x%h act=0x%h)",        m_data,          rhs.m_data)};
    return s;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    execute_out_transaction t;
    if (!$cast(t, rhs)) return 0;
    return (diff_string(t) == "");
  endfunction

  virtual function void do_copy(uvm_object rhs);
    execute_out_transaction t;
    super.do_copy(rhs);
    if (!$cast(t, rhs)) return;
    aluout = t.aluout;  pcout = t.pcout;  w_control_out = t.w_control_out;
    mem_control_out = t.mem_control_out;  dr = t.dr;  sr1 = t.sr1;  sr2 = t.sr2;
    ir_exec = t.ir_exec;  nzp = t.nzp;  m_data = t.m_data;
    index = t.index;  start_time = t.start_time;  end_time = t.end_time;
  endfunction

  virtual function void wave_view(int transaction_viewing_stream_h);
    transaction_view_h = $begin_transaction(transaction_viewing_stream_h, "execute_out_transaction", start_time);
    $add_attribute(transaction_view_h, aluout,          "aluout");
    $add_attribute(transaction_view_h, pcout,           "pcout");
    $add_attribute(transaction_view_h, w_control_out,   "w_control_out");
    $add_attribute(transaction_view_h, mem_control_out, "mem_control_out");
    $add_attribute(transaction_view_h, dr,              "dr");
    $add_attribute(transaction_view_h, sr1,             "sr1");
    $add_attribute(transaction_view_h, sr2,             "sr2");
    $add_attribute(transaction_view_h, ir_exec,         "ir_exec");
    $add_attribute(transaction_view_h, nzp,             "nzp");
    $add_attribute(transaction_view_h, m_data,          "m_data");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction
endclass : execute_out_transaction
