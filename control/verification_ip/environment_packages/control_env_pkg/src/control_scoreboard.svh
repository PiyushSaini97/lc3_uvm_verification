// control_scoreboard
// In-order scoreboard, same idea as P2's decode_scoreboard (analysis_imp_decl,
// SystemVerilog queue, compare(), counts, report_phase), with two changes:
//
// 1. TWO queues (expected and actual) instead of one.
//    In P2 the actual transaction always arrived a clock after the expected one, so
//    "pop expected when actual arrives" was safe. Here both monitors fire on the SAME
//    clock edge, and the simulator may run the control_out monitor before the
//    control_in monitor -> predictor chain. Buffering both sides and comparing
//    whenever both have an entry makes the result independent of that ordering.
//
// 2. Unique imp suffixes (_control_expected/_control_actual).
//    `uvm_analysis_imp_decl declares a class at package scope. lc3_env_pkg will import
//    decode_env_pkg, control_env_pkg, ... together, so distinct names avoid any
//    ambiguity with decode_scoreboard's _expected/_actual.
`uvm_analysis_imp_decl(_control_expected)
`uvm_analysis_imp_decl(_control_actual)

class control_scoreboard extends uvm_component;
  `uvm_component_utils(control_scoreboard)

  uvm_analysis_imp_control_expected #(control_out_transaction, control_scoreboard) expected_export;
  uvm_analysis_imp_control_actual   #(control_out_transaction, control_scoreboard) actual_export;

  control_out_transaction expected_q[$];
  control_out_transaction actual_q[$];

  int unsigned expected_count;
  int unsigned actual_count;
  int unsigned compare_count;
  int unsigned match_count;
  int unsigned mismatch_count;
  int unsigned misalign_count;
  int unsigned max_mismatch_prints = 20;

  // Per-signal mismatch tallies -> the report shows which output is broken.
  int unsigned field_errors[string];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export",   this);
  endfunction

  virtual function void write_control_expected(control_out_transaction t);
    expected_q.push_back(t);
    expected_count++;
    try_compare();
  endfunction

  virtual function void write_control_actual(control_out_transaction t);
    actual_q.push_back(t);
    actual_count++;
    try_compare();
  endfunction

  // Associative-array entries are created explicitly: incrementing a missing entry
  // works but makes Questa print vsim-3829 warnings.
  protected function void bump(string name);
    if (!field_errors.exists(name)) field_errors[name] = 0;
    field_errors[name]++;
  endfunction

  protected function void tally_fields(control_out_transaction exp, control_out_transaction act);
    if (exp.enable_updatePC  !== act.enable_updatePC)  bump("enable_updatePC");
    if (exp.enable_fetch     !== act.enable_fetch)     bump("enable_fetch");
    if (exp.enable_decode    !== act.enable_decode)    bump("enable_decode");
    if (exp.enable_execute   !== act.enable_execute)   bump("enable_execute");
    if (exp.enable_writeback !== act.enable_writeback) bump("enable_writeback");
    if (exp.bypass_alu_1     !== act.bypass_alu_1)     bump("bypass_alu_1");
    if (exp.bypass_alu_2     !== act.bypass_alu_2)     bump("bypass_alu_2");
    if (exp.bypass_mem_1     !== act.bypass_mem_1)     bump("bypass_mem_1");
    if (exp.bypass_mem_2     !== act.bypass_mem_2)     bump("bypass_mem_2");
    if (exp.mem_state        !== act.mem_state)        bump("mem_state");
    if (exp.br_taken         !== act.br_taken)         bump("br_taken");
  endfunction

  protected function void try_compare();
    control_out_transaction exp, act;
    while (expected_q.size() > 0 && actual_q.size() > 0) begin
      exp = expected_q.pop_front();
      act = actual_q.pop_front();
      compare_count++;

      // Both monitors number post-reset cycles from 0; they must agree.
      if (exp.cycle != act.cycle) begin
        misalign_count++;
        `uvm_error("SCBD", $sformatf("stream misalignment: expected is for cycle %0d, actual is cycle %0d",
                                     exp.cycle, act.cycle))
      end

      if (act.compare(exp)) begin
        match_count++;
        `uvm_info("SCBD", $sformatf("MATCH cycle %0d: %s", act.cycle, act.convert2string()), UVM_HIGH)
      end
      else begin
        mismatch_count++;
        tally_fields(exp, act);
        if (mismatch_count <= max_mismatch_prints)
          `uvm_error("SCBD", $sformatf("MISMATCH cycle %0d @%0t:%s\n  expected: %s\n  actual  : %s",
                                       act.cycle, act.end_time, exp.diff_string(act),
                                       exp.convert2string(), act.convert2string()))
        else if (mismatch_count == max_mismatch_prints + 1)
          `uvm_warning("SCBD", "further mismatches are counted but not printed")
      end
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    string per_field = "";
    foreach (field_errors[name])
      per_field = {per_field, $sformatf("    %-18s : %0d\n", name, field_errors[name])};

    `uvm_info("SCBD", $sformatf({"\n---------------- CONTROL SCOREBOARD ----------------\n",
                                 "  Expected (predicted) cycles    : %0d\n",
                                 "  Actual (observed) cycles       : %0d\n",
                                 "  Comparisons made               : %0d\n",
                                 "  Matches                        : %0d\n",
                                 "  Mismatches                     : %0d\n",
                                 "  Misaligned comparisons         : %0d\n",
                                 "  Expected left unmatched        : %0d\n",
                                 "  Actual left unmatched          : %0d\n",
                                 "%s",
                                 "----------------------------------------------------"},
                                expected_count, actual_count, compare_count, match_count,
                                mismatch_count, misalign_count, expected_q.size(), actual_q.size(),
                                (per_field == "") ? "" : {"  Mismatches by signal:\n", per_field}),
              UVM_NONE)

    if (expected_q.size() != 0 || actual_q.size() != 0)
      `uvm_error("SCBD", $sformatf("unmatched transactions at end of test: expected=%0d actual=%0d",
                                   expected_q.size(), actual_q.size()))
    if (compare_count == 0)
      `uvm_error("SCBD", "no comparisons were made")
  endfunction
endclass : control_scoreboard
