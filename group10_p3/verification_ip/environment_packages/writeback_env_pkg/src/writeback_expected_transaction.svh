// Validity masks belong to the reference result, never to DUT observations.
class writeback_expected_transaction extends writeback_out_transaction;
  `uvm_object_utils(writeback_expected_transaction)
  bit check_vsr1, check_vsr2, check_psr;
  function new(string name = "writeback_expected_transaction");
    super.new(name);
  endfunction
  virtual function void do_copy(uvm_object rhs);
    writeback_expected_transaction other;
    if (!$cast(other, rhs)) begin
      `uvm_fatal("WB_COPY", "Expected reference-result type");
      return;
    end
    super.do_copy(rhs);
    check_vsr1 = other.check_vsr1;
    check_vsr2 = other.check_vsr2;
    check_psr  = other.check_psr;
  endfunction
  virtual function string convert2string();
    return {super.convert2string(), $sformatf(" check={%b,%b,%b}", check_vsr1, check_vsr2, check_psr)};
  endfunction
endclass
