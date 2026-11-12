module hdl_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  bit clock;
  bit reset;
  initial clock = 1'b0;
  always #5 clock = ~clock;
  initial begin
    reset = 1'b1;
    #22 reset = 1'b0;
  end

  tri        enable_decode;
  tri [15:0] dout;
  tri [15:0] npc_in;
  tri [15:0] IR;
  tri [15:0] npc_out;
  tri [5:0]  E_Control;
  tri [1:0]  W_Control;
  tri        Mem_Control;

  decode_in_if decode_in_if_i (
    .clock(clock), .reset(reset),
    .enable_decode(enable_decode), .dout(dout), .npc_in(npc_in));
  decode_in_driver_bfm  decode_in_driver_bfm_i  (decode_in_if_i);
  decode_in_monitor_bfm decode_in_monitor_bfm_i (decode_in_if_i);

  decode_out_if decode_out_if_i (
    .clock(clock), .reset(reset), .enable_decode(enable_decode),
    .IR(IR), .npc_out(npc_out), .E_Control(E_Control),
    .W_Control(W_Control), .Mem_Control(Mem_Control));
  decode_out_monitor_bfm decode_out_monitor_bfm_i (decode_out_if_i);

  Decode DUT (
    .clock         (clock),
    .reset         (reset),
    .enable_decode (enable_decode),
    .dout          (dout),
    .npc_in        (npc_in),
    .W_Control     (W_Control),
    .Mem_Control   (Mem_Control),
    .E_Control     (E_Control),
    .IR            (IR),
    .npc_out       (npc_out)
  );

  initial begin
    uvm_config_db #(virtual decode_in_driver_bfm  )::set(null, "*", "decode_in_if",  decode_in_driver_bfm_i);
    uvm_config_db #(virtual decode_in_monitor_bfm )::set(null, "*", "decode_in_if",  decode_in_monitor_bfm_i);
    uvm_config_db #(virtual decode_out_monitor_bfm)::set(null, "*", "decode_out_if", decode_out_monitor_bfm_i);
  end
endmodule : hdl_top
