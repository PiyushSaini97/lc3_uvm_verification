// control_predictor
// Subscribes to control_in transactions (one per clock) and predicts the controller
// outputs for that same clock with lc3_prediction_pkg::controller_model().
//
// IMPORTANT - controller_model() is STATEFUL:
//   It keeps `static` pipeline-valid flags (fe1/fe2/dec/exe_out_valid), the memory
//   FSM state and a has_been_reset flag between calls. Consequences:
//     1. It must be called exactly once per clock, in order. This predictor calls it
//        exactly once per write().
//     2. Nothing else in the testbench may call controller_model(); a second caller
//        would advance the same static state and corrupt every later prediction.
//     3. The model has no reset input, so a reset in the middle of a test cannot be
//        tracked; that case raises a fatal instead of silently mispredicting.
//
// START-UP ALIGNMENT (prime):
//   controller_model()'s first call is a start-up step (fetch=1, updatePC=0, nothing
//   valid yet). The spec's startup timing diagram puts that step in the LAST RESET
//   CYCLE: en_fetch is already high during reset, and the first instruction is
//   decoded in the second cycle after reset, executes in the third and writes back
//   in the fourth. Making the first call on the first post-reset cycle instead put
//   the model one cycle late, which caused the 4 startup mismatches in runs 2 and 3.
//   So the monitor delivers the last reset-cycle sample once, marked prime=1. It
//   advances the model's state and produces NO prediction: reset cycles are never
//   compared. Every post-reset cycle from cycle 0 on is predicted and compared.
class control_predictor extends uvm_subscriber #(control_in_transaction);
  `uvm_component_utils(control_predictor)

  uvm_analysis_port #(control_out_transaction) predicted_ap;

  int unsigned prediction_count;
  int unsigned x_input_count;
  bit          model_started;   // controller_model() has been called at least once
  bit          primed;          // start-up step taken from a reset-cycle sample

  function new(string name, uvm_component parent);
    super.new(name, parent);
    predicted_ap = new("predicted_ap", this);
  endfunction

  function void write(control_in_transaction t);
    control_out_transaction predicted;
    bit       enable_updatePC, enable_fetch, enable_decode, enable_execute, enable_writeback;
    bit       bypass_alu_1, bypass_alu_2, bypass_mem_1, bypass_mem_2;
    bit [1:0] mem_state;
    bit       br_taken;

    if (t.prime && model_started)
      `uvm_fatal(get_type_name(),
                 "reset seen mid-test: controller_model() keeps static state and cannot be re-reset")
    if (!t.prime && !model_started)
      `uvm_warning(get_type_name(),
                   "no reset-cycle sample before cycle 0: model starts one cycle late (expect start-up mismatches)")

    // controller_model takes 2-state inputs; X/Z become 0. Worth knowing when debugging.
    if (t.has_unknown()) begin
      x_input_count++;
      `uvm_info(get_type_name(), {"X/Z on controller input (treated as 0): ", t.convert2string()}, UVM_HIGH)
    end

    if (controller_model(t.complete_data, t.complete_instr, t.IR, t.psr, t.IR_Exec, t.IMem_dout, t.NZP,
                         enable_updatePC, enable_fetch, enable_decode, enable_execute, enable_writeback,
                         bypass_alu_1, bypass_alu_2, bypass_mem_1, bypass_mem_2, mem_state, br_taken))
      `uvm_error(get_type_name(), {"controller_model failed for ", t.convert2string()})
    model_started = 1;

    // Start-up step only: no prediction, nothing for the scoreboard to compare.
    if (t.prime) begin
      primed = 1;
      `uvm_info(get_type_name(), "model start-up step taken on the last reset cycle (not compared)", UVM_MEDIUM)
      return;
    end

    predicted = control_out_transaction::type_id::create("predicted");
    predicted.enable_updatePC  = enable_updatePC;
    predicted.enable_fetch     = enable_fetch;
    predicted.enable_decode    = enable_decode;
    predicted.enable_execute   = enable_execute;
    predicted.enable_writeback = enable_writeback;
    predicted.bypass_alu_1     = bypass_alu_1;
    predicted.bypass_alu_2     = bypass_alu_2;
    predicted.bypass_mem_1     = bypass_mem_1;
    predicted.bypass_mem_2     = bypass_mem_2;
    predicted.mem_state        = mem_state;
    predicted.br_taken         = br_taken;
    predicted.cycle            = t.cycle;      // tag with the cycle it predicts
    predicted.start_time       = t.start_time;
    predicted.end_time         = t.end_time;
    prediction_count++;

    `uvm_info(get_type_name(), {"predicted: ", predicted.convert2string()}, UVM_HIGH)
    predicted_ap.write(predicted);
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("predictions made: %0d, start-up step on reset cycle: %s (cycles with X/Z inputs: %0d)",
                                         prediction_count, primed ? "yes" : "NO", x_input_count), UVM_LOW)
  endfunction
endclass : control_predictor
