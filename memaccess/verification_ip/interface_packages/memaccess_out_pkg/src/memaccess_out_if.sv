// memaccess_out_if
// Signal bundle for the MemAccess block's outputs (LC3 Design Spec, MEM ACCESS).
// `input` ports for the same reason as control_out_if: the agent is passive in both
// benches, because nothing except MemAccess ever drives these nets.
//
// In the LC3, Data_addr, Data_din and Data_rd are top-level output ports driven
// straight from this block, and memout feeds Writeback and Execute's memory bypass.
interface memaccess_out_if (
  input  wire        clock,
  input  wire        reset,
  input  tri  [15:0] Data_addr,   // address presented to data memory
  input  tri  [15:0] Data_din,    // write data to data memory
  input  tri         Data_rd,     // 1 = read, 0 = write
  input  tri  [15:0] memout       // word returned to Writeback / memory bypass
);
endinterface : memaccess_out_if
