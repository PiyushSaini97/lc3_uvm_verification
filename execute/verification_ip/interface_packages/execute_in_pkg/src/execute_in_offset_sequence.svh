// execute_in_offset_sequence
// The instructions that compute pcout: BR, JMP, LD, LDR, LDI, LEA, ST, STR, STI, with
// offsets, base register values and npc at the ends of their ranges, including wrap
// around at 0x0000 and 0xffff.
class execute_in_offset_sequence extends execute_in_sequence_base;
  `uvm_object_utils(execute_in_offset_sequence)

  function new(string name = "execute_in_offset_sequence");
    super.new(name);
  endfunction

  virtual task body();
    execute_in_transaction tr;
    for (int i = 0; i < num_items; i++) begin
      tr = execute_in_transaction::type_id::create("tr");
      start_item(tr);
      if (!tr.randomize() with {
            !(ir[15:12] inside {4'b0001, 4'b0101, 4'b1001});
            vsr1 dist {16'h0000 := 2, 16'h0001 := 2, 16'h7fff := 2, 16'h8000 := 2, 16'hffff := 2,
                       [16'h0002:16'h7ffe] :/ 2, [16'h8001:16'hfffe] :/ 2};
            npc_in dist {16'h0000 := 2, 16'h0001 := 2, 16'h8000 := 2, 16'hffff := 2,
                         [16'h0002:16'h7fff] :/ 2, [16'h8001:16'hfffe] :/ 2};
            ir[8:0] dist {9'h000 := 2, 9'h0ff := 2, 9'h100 := 2, 9'h1ff := 2,
                          [9'h001:9'h0fe] :/ 2, [9'h101:9'h1fe] :/ 2};
          })
        `uvm_fatal("RAND", "randomize failed")
      finish_item(tr);
    end
  endtask
endclass : execute_in_offset_sequence
