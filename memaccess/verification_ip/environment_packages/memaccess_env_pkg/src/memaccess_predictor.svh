// memaccess_predictor
// Subscribes to memaccess_in transactions (one per clock) and predicts the MemAccess
// outputs for that same clock with lc3_prediction_pkg::mem_access_model().
//
// mem_access_model() is a PURE function. Unlike controller_model() it keeps no
// static state, so:
//   * there is no start-up step and no priming, which is why this predictor is much
//     simpler than control_predictor;
//   * calling it more than once per cycle, or out of order, is harmless;
//   * other components may call it too, if they ever need to.
//
// UNDEFINED INPUTS
//   mem_access_model() takes 2-state `bit` arguments, so an x or z on an input
//   silently becomes 0 inside it. The RTL propagates x instead, so comparing those
//   cycles would report mismatches that say nothing about the design. When an input
//   the model actually reads in the current state is undefined, this predictor still
//   emits a transaction, so the expected and actual streams stay one-for-one, but
//   marks it dont_care and the scoreboard skips the comparison and counts it.
//
//   Which inputs are read depends on the state (see mem_access_model):
//     every state : Data_dout  - memout forwards it unchanged, IDLE included
//     IDLE    (3) : nothing else; the outputs are tri-stated
//     RD_IND  (1) : M_Addr
//     RD_DIR  (0) : M_Control, then M_Addr if direct (Data_dout if indirect)
//     WRITE   (2) : M_Control and M_Data, then M_Addr if direct
//
//   In the memaccess block bench every input is always driven, so nothing is ever
//   skipped. This matters only at LC3 level, in the cycles after reset before the
//   first instruction has reached Execute.
class memaccess_predictor extends uvm_subscriber #(memaccess_in_transaction);
  `uvm_component_utils(memaccess_predictor)

  uvm_analysis_port #(memaccess_out_transaction) predicted_ap;

  int unsigned prediction_count;
  int unsigned skipped_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    predicted_ap = new("predicted_ap", this);
  endfunction

  // True when every input the model reads in this cycle's state is fully defined.
  protected function bit inputs_defined(memaccess_in_transaction t);
    if ($isunknown(t.mem_state)) return 1'b0;
    if ($isunknown(t.Data_dout)) return 1'b0;   // memout forwards it in every state
    case (t.mem_state)
      2'd3    : return 1'b1;
      2'd1    : return !$isunknown(t.M_Addr);
      2'd0    : begin
                  if ($isunknown(t.M_Control)) return 1'b0;
                  return t.M_Control ? 1'b1 : !$isunknown(t.M_Addr);
                end
      2'd2    : begin
                  if ($isunknown(t.M_Control)) return 1'b0;
                  if ($isunknown(t.M_Data))    return 1'b0;
                  return t.M_Control ? 1'b1 : !$isunknown(t.M_Addr);
                end
      default : return 1'b0;
    endcase
  endfunction

  function void write(memaccess_in_transaction t);
    memaccess_out_transaction predicted;
    bit [15:0] DMem_addr, DMem_din, memout;
    bit        DMem_rd;
    bit        defined;

    defined = inputs_defined(t);

    if (mem_access_model(t.M_Data, t.M_Addr, t.M_Control, t.mem_state, t.Data_dout,
                         DMem_addr, DMem_din, memout, DMem_rd))
      `uvm_error(get_type_name(), {"mem_access_model failed for ", t.convert2string()})

    predicted           = memaccess_out_transaction::type_id::create("predicted");
    predicted.Data_addr = DMem_addr;
    predicted.Data_din  = DMem_din;
    predicted.Data_rd   = DMem_rd;
    predicted.memout    = memout;

    // IDLE: restore the tri-state the model intends but cannot return.
    //
    // mem_access_model() assigns 16'hzzzz / 1'bz for mem_state == 3, but its output
    // formals are declared `output bit`, which is 2-state. SystemVerilog converts
    // z to 0 at that assignment, inside the function, so the caller receives
    // 0x0000 / 0 no matter how it declares its own variables. The z is destroyed
    // before the function returns.
    //
    // Measured on Questa: without this, every IDLE cycle mismatches on Data_addr,
    // Data_din and Data_rd (885 of 2269 cycles in a default run), with expected
    // 0x0000/0 against the RTL's correct 0xzzzz/z. memout is unaffected, because
    // the model forwards Data_dout and never drives it to z.
    //
    // The RTL is right and the model's intent is right; only the `bit` return type
    // is wrong. So the predictor restores the intent rather than relaxing the check,
    // and the comparison against the real outputs stays strict.
    if (t.mem_state === 2'd3) begin
      predicted.Data_addr = 16'hzzzz;
      predicted.Data_din  = 16'hzzzz;
      predicted.Data_rd   = 1'bz;
    end
    predicted.cycle     = t.cycle;          // tag with the cycle it predicts
    predicted.dont_care = !defined;
    predicted.start_time = t.start_time;
    predicted.end_time   = t.end_time;

    if (defined) begin
      prediction_count++;
      `uvm_info(get_type_name(), {"predicted: ", predicted.convert2string()}, UVM_HIGH)
    end
    else begin
      skipped_count++;
      `uvm_info(get_type_name(),
                {"undefined inputs, cycle not compared: ", t.convert2string()}, UVM_HIGH)
    end

    predicted_ap.write(predicted);
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("predictions made: %0d (cycles skipped for undefined inputs: %0d)",
                        prediction_count, skipped_count),
              UVM_LOW)
  endfunction
endclass : memaccess_predictor
