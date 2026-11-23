// execute_scoreboard
// In-order scoreboard in the style of control_scoreboard: two queues (expected, actual)
// and a compare whenever both have an entry, so the result does not depend on which
// monitor fires first. Imp suffixes are unique to this env so lc3_env_pkg can import
// decode_env_pkg, control_env_pkg and execute_env_pkg together.
`uvm_analysis_imp_decl(_execute_expected)
`uvm_analysis_imp_decl(_execute_actual)

class execute_scoreboard extends uvm_component;
  `uvm_component_utils(execute_scoreboard)

  uvm_analysis_imp_execute_expected #(execute_out_transaction, execute_scoreboard) expected_export;
  uvm_analysis_imp_execute_actual #(execute_out_transaction, execute_scoreboard) actual_export;

  execute_out_transaction expected_q[$];
  execute_out_transaction actual_q[$];

  int unsigned expected_count;
  int unsigned actual_count;
  int unsigned compare_count;
  int unsigned match_count;
  int unsigned mismatch_count;
  int unsigned misalign_count;
  int unsigned max_mismatch_prints = 20;

  int unsigned field_errors[string];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
  endfunction

  virtual function void write_execute_expected(execute_out_transaction t);
    expected_q.push_back(t);
    expected_count++;
    try_compare();
    if (expected_q.size() > 8 || actual_q.size() > 8) `uvm_fatal("LC3_BACKLOG", "Stage stream backlog");
  endfunction

  virtual function void write_execute_actual(execute_out_transaction t);
    actual_q.push_back(t);
    actual_count++;
    try_compare();
    if (expected_q.size() > 8 || actual_q.size() > 8) `uvm_fatal("LC3_BACKLOG", "Stage stream backlog");
  endfunction

  protected function void bump(string name);
    if (!field_errors.exists(name)) field_errors[name] = 0;
    field_errors[name]++;
  endfunction

  protected function void tally_fields(execute_out_transaction exp, execute_out_transaction act);
    if (exp.aluout !== act.aluout) bump("aluout");
    if (exp.pcout !== act.pcout) bump("pcout");
    if (exp.w_control_out !== act.w_control_out) bump("w_control_out");
    if (exp.mem_control_out !== act.mem_control_out) bump("mem_control_out");
    if (exp.dr !== act.dr) bump("dr");
    if (exp.sr1 !== act.sr1) bump("sr1");
    if (exp.sr2 !== act.sr2) bump("sr2");
    if (exp.ir_exec !== act.ir_exec) bump("ir_exec");
    if (exp.nzp !== act.nzp) bump("nzp");
    if (exp.m_data !== act.m_data) bump("m_data");
  endfunction

  protected function void try_compare();
    execute_out_transaction exp, act;
    while (expected_q.size() > 0 && actual_q.size() > 0) begin
      exp = expected_q.pop_front();
      act = actual_q.pop_front();
      compare_count++;

      if (exp.index != act.index) begin
        misalign_count++;
        `uvm_error("SCBD", $sformatf(
                   "stream misalignment: expected is for txn %0d, actual is txn %0d", exp.index, act.index));
      end

      if (act.compare(exp)) begin
        match_count++;
        `uvm_info("SCBD", $sformatf("MATCH %s", act.convert2string()), UVM_HIGH);
      end else begin
        mismatch_count++;
        tally_fields(exp, act);
        if (mismatch_count <= max_mismatch_prints)
          `uvm_error("SCBD", $sformatf(
                     "MISMATCH txn %0d @%0t:%s\n  expected: %s\n  actual  : %s",
                     act.index,
                     act.end_time,
                     exp.diff_string(
                         act
                     ),
                     exp.convert2string(),
                     act.convert2string()
                     ))
        else if (mismatch_count == max_mismatch_prints + 1)
          `uvm_warning("SCBD", "further mismatches are counted but not printed");
      end
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    string per_field;
    per_field = "";
    foreach (field_errors[name])
    per_field = {per_field, $sformatf("    %-18s : %0d\n", name, field_errors[name])};

    `uvm_info("SCBD", $sformatf(
              {
                "\n---------------- EXECUTE SCOREBOARD ----------------\n",
                "  Expected (predicted) txns      : %0d\n",
                "  Actual (observed) txns         : %0d\n",
                "  Comparisons made               : %0d\n",
                "  Matches                        : %0d\n",
                "  Mismatches                     : %0d\n",
                "  Misaligned comparisons         : %0d\n",
                "  Expected left unmatched        : %0d\n",
                "  Actual left unmatched          : %0d\n",
                "%s",
                "----------------------------------------------------"
              },
              expected_count,
              actual_count,
              compare_count,
              match_count,
              mismatch_count,
              misalign_count,
              expected_q.size(),
              actual_q.size(),
              (per_field == "") ? "" : {"  Mismatches by signal:\n", per_field}
              ), UVM_NONE);

    if (expected_q.size() != 0 || actual_q.size() != 0)
      `uvm_error("SCBD", $sformatf(
                 "unmatched transactions at end of test: expected=%0d actual=%0d",
                 expected_q.size(),
                 actual_q.size()));
    if (compare_count == 0) `uvm_error("SCBD", "no comparisons were made");
  endfunction
endclass : execute_scoreboard
