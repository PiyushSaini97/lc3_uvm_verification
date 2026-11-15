// execute_in_alu_sequence
// ADD, AND, NOT with operand corner values: zero, one, largest positive, most negative,
// all ones, and immediates at the ends of the imm5 range. Targets aluout overflow and
// sign handling.
class execute_in_alu_sequence extends execute_in_sequence_base;
  `uvm_object_utils(execute_in_alu_sequence)

  function new(string name = "execute_in_alu_sequence");
    super.new(name);
  endfunction

  virtual task body();
    execute_in_transaction tr;
    for (int i = 0; i < num_items; i++) begin
      tr = execute_in_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize() with {
            ir[15:12] inside {4'b0001, 4'b0101, 4'b1001};
            vsr1 dist {16'h0000 := 2, 16'h0001 := 2, 16'h7fff := 2, 16'h8000 := 2, 16'hffff := 2,
                       [16'h0002:16'h7ffe] :/ 2, [16'h8001:16'hfffe] :/ 2};
            vsr2 dist {16'h0000 := 2, 16'h0001 := 2, 16'h7fff := 2, 16'h8000 := 2, 16'hffff := 2,
                       [16'h0002:16'h7ffe] :/ 2, [16'h8001:16'hfffe] :/ 2};
            mem_bypass_val dist {16'h0000 := 1, 16'h7fff := 1, 16'h8000 := 1, 16'hffff := 1,
                                 [16'h0001:16'hfffe] :/ 2};
            ir[4:0] dist {5'h00 := 2, 5'h0f := 2, 5'h10 := 2, 5'h1f := 2,
                          [5'h01:5'h0e] :/ 2, [5'h11:5'h1e] :/ 2};
          })
        `uvm_fatal("RAND", "randomize failed")
      finish_item(tr);
    end
  endtask
endclass : execute_in_alu_sequence
