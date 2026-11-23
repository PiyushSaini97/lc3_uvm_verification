// Observed pins stay four-state: X/Z must not silently become zero.
class writeback_out_transaction extends uvm_sequence_item;
  `uvm_object_utils(writeback_out_transaction)
  logic                   reset;
  logic            [15:0] vsr1;
  logic            [15:0] vsr2;
  logic            [ 2:0] psr;
  longint unsigned        cycle_id;
  time                    sample_time;

  function new(string name = "writeback_out_transaction");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    writeback_out_transaction other;
    if (!$cast(other, rhs)) begin
      `uvm_fatal("WB_COPY", "Wrong transaction type");
      return;
    end
    super.do_copy(rhs);
    reset       = other.reset;
    vsr1        = other.vsr1;
    vsr2        = other.vsr2;
    psr         = other.psr;
    cycle_id    = other.cycle_id;
    sample_time = other.sample_time;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    writeback_out_transaction other;
    if (!$cast(other, rhs)) return 0;
    return super.do_compare(
        rhs, comparer
    ) && (cycle_id == other.cycle_id) && (reset === other.reset) && (vsr1 === other.vsr1) &&
        (vsr2 === other.vsr2) && (psr === other.psr);
  endfunction

  virtual function string convert2string();
    return $sformatf("cycle=%0d time=%0t reset=%h vsr1=%h vsr2=%h psr=%h", cycle_id, sample_time, reset, vsr1,
                     vsr2, psr);
  endfunction
endclass
