// execute_in_transaction
// One Execute cycle with enable_execute high: everything the Execute stage consumes.
// The same class is the sequence item (execute block bench) and what the monitor
// observes (both benches).
class execute_in_transaction extends uvm_sequence_item;
  `uvm_object_utils(execute_in_transaction)

  rand bit [5:0]  e_control;
  rand bit [15:0] ir;
  rand bit [15:0] npc_in;
  rand bit        bypass_alu_1, bypass_alu_2, bypass_mem_1, bypass_mem_2;
  rand bit [15:0] vsr1, vsr2;
  rand bit [15:0] mem_bypass_val;
  rand bit [1:0]  w_control_in;
  rand bit        mem_control_in;
  time            start_time, end_time;
  int             transaction_view_h;
  int unsigned    index;

  // knobs, not randomized
  bit       force_opcode     = 0;   // 1: opcode comes from forced_opcode
  bit [3:0] forced_opcode;
  bit       legal_controls   = 1;   // 1: e_control / w_control / mem_control follow the opcode as Decode makes them
  bit       realistic_bypass = 1;   // 1: bypass only asserted for operands the instruction really uses

  // same 12 opcodes and encoding rule as P2's decode_in
  constraint valid_opcode {
    if (force_opcode) {
      ir[15:12] == forced_opcode;
    }
    else {
      ir[15:12] inside {4'b0000, 4'b0001, 4'b0010, 4'b0011,
                        4'b0101, 4'b0110, 4'b0111, 4'b1001,
                        4'b1010, 4'b1011, 4'b1100, 4'b1110};
    }
    (ir[15:12] == 4'b1001) -> (ir[5:0] == 6'b111111);
  }

  // table taken from decode_model in lc3_prediction_pkg
  constraint controls_match_opcode {
    if (legal_controls) {
      (ir[15:12] == 4'b0001) -> (w_control_in == 0 && mem_control_in == 0 &&
                                 e_control == (ir[5] ? 6'b000000 : 6'b000001));
      (ir[15:12] == 4'b0101) -> (w_control_in == 0 && mem_control_in == 0 &&
                                 e_control == (ir[5] ? 6'b010000 : 6'b010001));
      (ir[15:12] == 4'b1001) -> (w_control_in == 0 && mem_control_in == 0 && e_control == 6'b100000);
      (ir[15:12] == 4'b0000) -> (w_control_in == 0 && mem_control_in == 0 && e_control == 6'b000110);
      (ir[15:12] == 4'b1100) -> (w_control_in == 0 && mem_control_in == 0 && e_control == 6'b001100);
      (ir[15:12] == 4'b0010) -> (w_control_in == 1 && mem_control_in == 0 && e_control == 6'b000110);
      (ir[15:12] == 4'b0110) -> (w_control_in == 1 && mem_control_in == 0 && e_control == 6'b001000);
      (ir[15:12] == 4'b1010) -> (w_control_in == 1 && mem_control_in == 1 && e_control == 6'b000110);
      (ir[15:12] == 4'b1110) -> (w_control_in == 2 && mem_control_in == 0 && e_control == 6'b000110);
      (ir[15:12] == 4'b0011) -> (w_control_in == 0 && mem_control_in == 0 && e_control == 6'b000110);
      (ir[15:12] == 4'b0111) -> (w_control_in == 0 && mem_control_in == 0 && e_control == 6'b001000);
      (ir[15:12] == 4'b1011) -> (w_control_in == 0 && mem_control_in == 1 && e_control == 6'b000110);
    }
  }

  // execute_model asserts that alu and mem bypass are never both set for one operand
  constraint bypass_rules {
    !(bypass_alu_1 && bypass_mem_1);
    !(bypass_alu_2 && bypass_mem_2);
    if (realistic_bypass) {
      // operand 1 is only used by ADD, AND, NOT, LDR, STR, JMP
      !(ir[15:12] inside {4'b0001, 4'b0101, 4'b1001, 4'b0110, 4'b0111, 4'b1100})
        -> (!bypass_alu_1 && !bypass_mem_1);
      // operand 2 is used by register-mode ADD and AND, and as store data by ST, STR, STI
      !((ir[15:12] inside {4'b0001, 4'b0101} && !ir[5]) ||
        (ir[15:12] inside {4'b0011, 4'b0111, 4'b1011}))
        -> (!bypass_alu_2 && !bypass_mem_2);
    }
  }

  function new(string name = "execute_in_transaction");
    super.new(name);
  endfunction

  virtual function void wave_view(int transaction_viewing_stream_h);
    transaction_view_h = $begin_transaction(transaction_viewing_stream_h, "execute_in_transaction", start_time);
    $add_attribute(transaction_view_h, e_control,      "e_control");
    $add_attribute(transaction_view_h, ir,             "ir");
    $add_attribute(transaction_view_h, npc_in,         "npc_in");
    $add_attribute(transaction_view_h, bypass_alu_1,   "bypass_alu_1");
    $add_attribute(transaction_view_h, bypass_alu_2,   "bypass_alu_2");
    $add_attribute(transaction_view_h, bypass_mem_1,   "bypass_mem_1");
    $add_attribute(transaction_view_h, bypass_mem_2,   "bypass_mem_2");
    $add_attribute(transaction_view_h, vsr1,           "vsr1");
    $add_attribute(transaction_view_h, vsr2,           "vsr2");
    $add_attribute(transaction_view_h, mem_bypass_val, "mem_bypass_val");
    $add_attribute(transaction_view_h, w_control_in,   "w_control_in");
    $add_attribute(transaction_view_h, mem_control_in, "mem_control_in");
    $end_transaction(transaction_view_h, end_time);
    $free_transaction(transaction_view_h);
  endfunction

  virtual function string convert2string();
    return $sformatf("#%0d e_control:0x%h ir:0x%h npc_in:0x%h byp_alu:%0b%0b byp_mem:%0b%0b vsr1:0x%h vsr2:0x%h mem_byp:0x%h w_ctl_in:0x%h m_ctl_in:%0b",
                     index, e_control, ir, npc_in, bypass_alu_1, bypass_alu_2,
                     bypass_mem_1, bypass_mem_2, vsr1, vsr2, mem_bypass_val,
                     w_control_in, mem_control_in);
  endfunction
endclass : execute_in_transaction
