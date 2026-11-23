`uvm_analysis_imp_decl(_decode_expected)
`uvm_analysis_imp_decl(_decode_actual)
class decode_scoreboard extends uvm_component;
  `uvm_component_utils(decode_scoreboard)
  uvm_analysis_imp_decode_expected #(decode_out_transaction, decode_scoreboard) expected_export;
  uvm_analysis_imp_decode_actual #(decode_out_transaction, decode_scoreboard) actual_export;
  decode_out_transaction expected_q[$], actual_q[$];
  int unsigned compare_count, mismatch_count;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
  endfunction
  function void write_decode_expected(decode_out_transaction t);
    expected_q.push_back(t);
    drain();
  endfunction
  function void write_decode_actual(decode_out_transaction t);
    actual_q.push_back(t);
    drain();
  endfunction
  function void drain();
    decode_out_transaction e, a;
    while (expected_q.size() > 0 && actual_q.size() > 0) begin
      e = expected_q.pop_front();
      a = actual_q.pop_front();
      compare_count++;
      if (!a.compare(e)) begin
        mismatch_count++;
        `uvm_error("DECODE_MISMATCH", {e.convert2string(), " / ", a.convert2string()});
      end
    end
    if (expected_q.size() > 8 || actual_q.size() > 8) `uvm_fatal("LC3_BACKLOG", "Decode backlog");
  endfunction
  function void check_phase(uvm_phase phase);
    if (compare_count == 0 || expected_q.size() != 0 || actual_q.size() != 0)
      `uvm_error("LC3_NO_CHECKS", "Decode missing traffic or unpaired samples");
  endfunction
  function void report_phase(uvm_phase phase);
    `uvm_info("DECODE_SUMMARY", $sformatf("checks=%0d mismatch=%0d", compare_count, mismatch_count),
              UVM_NONE);
  endfunction
endclass
