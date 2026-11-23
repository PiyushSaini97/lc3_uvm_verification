// Observed pins stay four-state: X/Z must not silently become zero.
class writeback_in_transaction extends uvm_sequence_item;
  `uvm_object_utils(writeback_in_transaction)
  logic                   reset;
  logic                   enable_writeback;
  logic            [ 1:0] W_Control;
  logic            [15:0] aluout;
  logic            [15:0] npc;
  logic            [15:0] pcout;
  logic            [15:0] memout;
  logic            [ 2:0] sr1;
  logic            [ 2:0] sr2;
  logic            [ 2:0] dr;
  longint unsigned        cycle_id;
  time                    sample_time;

  function new(string name = "writeback_in_transaction");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    writeback_in_transaction other;
    if (!$cast(other, rhs)) begin
      `uvm_fatal("WB_COPY", "Wrong transaction type");
      return;
    end
    super.do_copy(rhs);
    reset            = other.reset;
    enable_writeback = other.enable_writeback;
    W_Control        = other.W_Control;
    aluout           = other.aluout;
    npc              = other.npc;
    pcout            = other.pcout;
    memout           = other.memout;
    sr1              = other.sr1;
    sr2              = other.sr2;
    dr               = other.dr;
    cycle_id         = other.cycle_id;
    sample_time      = other.sample_time;
  endfunction

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    writeback_in_transaction other;
    if (!$cast(other, rhs)) return 0;
    return super.do_compare(
        rhs, comparer
    ) && (cycle_id == other.cycle_id) && (reset === other.reset) &&
        (enable_writeback === other.enable_writeback) && (W_Control === other.W_Control) &&
        (aluout === other.aluout) && (npc === other.npc) && (pcout === other.pcout) &&
        (memout === other.memout) && (sr1 === other.sr1) && (sr2 === other.sr2) && (dr === other.dr);
  endfunction

  virtual function string convert2string();
    return $sformatf(
        "cycle=%0d time=%0t reset=%h enable_writeback=%h W_Control=%h aluout=%h npc=%h pcout=%h memout=%h sr1=%h sr2=%h dr=%h",
        cycle_id,
        sample_time,
        reset,
        enable_writeback,
        W_Control,
        aluout,
        npc,
        pcout,
        memout,
        sr1,
        sr2,
        dr
    );
  endfunction
endclass
