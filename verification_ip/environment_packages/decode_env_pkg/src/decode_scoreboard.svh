`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class decode_scoreboard extends uvm_component;
  `uvm_component_utils(decode_scoreboard)

  uvm_analysis_imp_expected #(decode_out_transaction, decode_scoreboard) expected_export;
  uvm_analysis_imp_actual   #(decode_out_transaction, decode_scoreboard) actual_export;

  decode_out_transaction expected_q[$];

  int unsigned expected_count;
  int unsigned actual_count;
  int unsigned compare_count;
  int unsigned match_count;
  int unsigned mismatch_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
  endfunction

  virtual function void write_expected(decode_out_transaction t);
    expected_q.push_back(t);
    expected_count++;
  endfunction

  virtual function void write_actual(decode_out_transaction t);
    decode_out_transaction expected;
    actual_count++;

    if (expected_q.size() == 0) begin
      `uvm_error("SCBD", {"actual transaction with no expected transaction queued: ", t.convert2string()})
      return;
    end

    expected = expected_q.pop_front();
    compare_count++;

    if (t.compare(expected)) begin
      match_count++;
      `uvm_info("SCBD", $sformatf("MATCH #%0d: %s", compare_count, t.convert2string()), UVM_LOW)
    end
    else begin
      mismatch_count++;
      `uvm_error("SCBD", $sformatf("MISMATCH #%0d\n  expected: %s\n  actual  : %s",
                                   compare_count, expected.convert2string(), t.convert2string()))
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info("SCBD", $sformatf({"\n---------------- DECODE SCOREBOARD ----------------\n",
                                 "  Expected transactions received : %0d\n",
                                 "  Actual transactions received   : %0d\n",
                                 "  Comparisons made               : %0d\n",
                                 "  Matches                        : %0d\n",
                                 "  Mismatches                     : %0d\n",
                                 "  Expected left in queue         : %0d\n",
                                 "---------------------------------------------------"},
                                expected_count, actual_count, compare_count,
                                match_count, mismatch_count, expected_q.size()), UVM_NONE)

    if (expected_q.size() != 0)
      `uvm_error("SCBD", $sformatf("%0d expected transactions never compared", expected_q.size()))
    if (compare_count == 0)
      `uvm_error("SCBD", "no comparisons were made")
  endfunction
endclass : decode_scoreboard
