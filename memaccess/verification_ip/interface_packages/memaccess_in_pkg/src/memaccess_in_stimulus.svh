// memaccess_in_stimulus
// What the TEST controls: one clock cycle's worth of MemAccess inputs.
//
// Kept separate from memaccess_in_transaction on purpose, the same split control_in
// makes. The transaction is what the monitor OBSERVES (4-state, carries a cycle
// number). The stimulus is what the sequence DRIVES (2-state, randomizable).
//
// The value distributions exist so the corner values the coverage model asks for
// (zero and all-ones on each 16-bit port) show up without a directed test for each.
class memaccess_in_stimulus extends uvm_sequence_item;
  `uvm_object_utils(memaccess_in_stimulus)

  rand bit [1:0]  mem_state;
  rand bit        M_Control;
  rand bit [15:0] M_Data;
  rand bit [15:0] M_Addr;
  rand bit [15:0] Data_dout;

  // Weighted so 0x0000 and 0xFFFF appear regularly instead of once every 65536 items.
  //
  // The range MUST use `:/`, not `:=`. With `:=` the weight is applied to EVERY
  // value in the range, so [1:FFFE] carries 65534 x 8 = 524272 against 1 each for
  // the two corners, and the corners effectively never occur. Measured on Questa
  // with `:=`: 0x0000 appeared twice in 2269 cycles (both from the driver's reset
  // values, not from randomization) and 0xFFFF never, leaving `bin max` empty on
  // M_Addr, M_Data and Data_dout and dragging four coverpoints and two crosses
  // down with it. With `:/` the weight is shared across the range, giving the
  // intended 10% / 10% / 80% split.
  constraint c_corner_values {
    M_Data    dist { 16'h0000 := 1, 16'hFFFF := 1, [16'h0001:16'hFFFE] :/ 8 };
    M_Addr    dist { 16'h0000 := 1, 16'hFFFF := 1, [16'h0001:16'hFFFE] :/ 8 };
    Data_dout dist { 16'h0000 := 1, 16'hFFFF := 1, [16'h0001:16'hFFFE] :/ 8 };
  }

  function new(string name = "memaccess_in_stimulus");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("mem_state=%0d M_Control=%b M_Data=0x%4h M_Addr=0x%4h Data_dout=0x%4h",
                     mem_state, M_Control, M_Data, M_Addr, Data_dout);
  endfunction
endclass : memaccess_in_stimulus
