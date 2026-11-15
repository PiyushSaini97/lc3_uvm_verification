# LC3 Project 3: Execute stage UVM packages

This covers the Execute part of the LC3 bench (P3 slides 4, 7 and 8), plus a standalone execute block bench:

| Package | Location | Role |
|---|---|---|
| `execute_in_pkg` | `verification_ip/interface_packages/execute_in_pkg` | Agent for the Execute's 12 inputs. **Active** in the execute bench, **passive** in the LC3 bench |
| `execute_out_pkg` | `verification_ip/interface_packages/execute_out_pkg` | Passive agent that watches the Execute's 10 outputs |
| `execute_env_pkg` | `verification_ip/environment_packages/execute_env_pkg` | Env config, predictor (`execute_model`), scoreboard and environment |
| execute block bench | `project_benches/execute` | Runs Execute on its own, like the decode and control benches |

LC3-level integration pieces, to merge into your LC3 bench later:

- `project_benches/lc3/tb/testbench/hdl_top_execute_snippet.sv`: interfaces, BFMs and `uvm_config_db` sets.
- `project_benches/lc3/sim/files_execute.f`: lines to add to `files.f`, in compile order.
- `project_benches/lc3/integration/lc3_env_execute_hookup.svh`: how `lc3_env_configuration` and `lc3_environment` instantiate and initialize the execute environment.

The LC3 snippet connects to the nets of the `LC3` top (`DUT.IR`, `DUT.npc_out_dec`, `DUT.memout`, ...) rather than reaching into the `Ex` instance. Check that `` `define LC3_TOP_PATH DUT `` matches the instance name you give `LC3` in `hdl_top`.

---

## Running the execute block bench

```
cd project_benches/execute/sim
make execute_debug                         # GUI + wave.do
make execute_batch                         # batch, saves execute_coverage.ucdb
make execute_debug VERBOSITY=UVM_HIGH      # print every transaction (MATCH lines, monitors, driver)
make execute_batch ITEMS=1000              # items per sequence (default 200)
```

`rtl/` holds `Execute.v` and `data_defs.v` from `LC3_veloce_encrypted.zip`. The layout is the same as the control bench, so `files.f` reaches `verification_ip/` with the same `../../../` paths. The archive includes the course's `lc3_prediction_pkg`, unchanged. If you merge it into a tree that already has that package, keep one copy.

After changing files, run `make clean` before the next run so qrun's incremental session (`qrun.out`) rebuilds everything.

**What a passing run looks like:** at the end of the transcript, the `EXECUTE SCOREBOARD` report shows Comparisons = Matches = number of expected = number of actual, Mismatches 0, Misaligned 0, nothing left unmatched, and `UVM_ERROR : 0`. With the default `ITEMS=200` the test runs 5 sequences, so 1000 comparisons.

**How to read a failing run:** each mismatch prints only the signals that differ, with expected and actual values. The report's "Mismatches by signal" table tells you which output is wrong. Patterns to recognize:

- **Everything** mismatches from the first transaction, and expected looks like actual shifted by one: a sampling edge is off. Change the edge used in `execute_out_monitor_bfm` (Design decision 2).
- Only `sr1` / `sr2` mismatch everywhere: they are not latched the way the bench assumes. Remove the `sr1_d1` / `sr2_d1` delay in `execute_out_monitor_bfm` and read them live.
- Mismatches in specific situations only, such as `m_data` when `bypass_mem_2` is set, or `pcout` on ADD/AND/NOT: either an RTL bug, which is what P3 asks you to find, or a quirk of the model. Open the waves at the transaction's `@time`, compare against the spec and decide which side is wrong. Report model issues to the group rather than patching the model.

---

## The execute bench

Unlike the controller, Execute has no feedback into its own inputs, so the active driver is simple: one transaction per clock, all 12 inputs set together. The driver BFM holds `enable_execute` high for the whole run and the input monitor only captures cycles where it is high and reset is low.

| Execute input | Comes from (LC3) | In the block bench |
|---|---|---|
| `enable_execute` | Controller | held high by the driver |
| `E_Control`, `IR`, `npc`, `W_Control_in`, `Mem_Control_in` | Decode | driven together; controls follow the opcode the way `decode_model` makes them |
| `bypass_alu_1/2`, `bypass_mem_1/2` | Controller | random, never both ALU and MEM for one operand |
| `VSR1`, `VSR2` | Writeback register file | random, with corner-value sequences |
| `Mem_Bypass_Val` | Mem Access (`memout`) | random |

**Stimulus rules** (constraints in `execute_in_transaction`):

- the same 12 opcodes as P2's `decode_in` (JSR, RTI, TRAP, RESERVED excluded); NOT always has `IR[5:0] = 111111`
- `legal_controls` (default 1): `E_Control`, `W_Control_in` and `Mem_Control_in` match the opcode, using the decode model's table
- `realistic_bypass` (default 1): a bypass is only asserted for an operand the instruction uses, since that is all the Controller can produce
- `force_opcode` / `forced_opcode`: used by the first 12 items of `execute_in_random_sequence` to hit every opcode once

Turn `legal_controls` or `realistic_bypass` off in a sequence if you want to see how Execute reacts to inputs it never gets in the LC3. Such mismatches are not bugs.

**Test plan in `test_top`**, five sequences of `ITEMS` items each:

1. **random**: every legal opcode once, then random. General sanity.
2. **alu**: ADD/AND/NOT with 0, 1, 0x7fff, 0x8000, 0xffff operands and imm5 at both ends. `aluout` overflow, sign and `NZP`.
3. **offset**: BR, JMP, LD, LDR, LDI, LEA, ST, STR, STI with offsets, base values and `npc` at the ends of their ranges. `pcout` and `M_Data`.
4. **bypass**: at least one bypass per item, across every opcode that uses that operand.
5. **random** again, so everything meets back-to-back.
After a run, check coverage: `execute_in_coverage` has opcode × bypass-source crosses per operand (restricted to opcodes that use the operand) and operand corner bins; `execute_out_coverage` has `W_Control_out`, `dr`/`sr1`/`sr2` and `aluout`/`pcout` bins, all 8 values of the `NZP` output, and the 8 BR condition values (`IR_Exec[11:9]`). `NZP` is the branch condition Execute passes on (BR gives `IR[11:9]`, JMP gives `111`, everything else `000`), not the flags of the ALU result. An empty bin means the tests never exercised that path.

---

## Design decisions and why

### 1. One transaction per enabled cycle
`execute_model()` is **stateful**. It keeps its previous outputs in static variables, because the ALU bypass reads the previous `aluout`. So:

- The input monitor emits a transaction on every rising edge where `enable_execute` is high and `reset` is low.
- `execute_predictor` calls `execute_model()` exactly once per input transaction, in order.
- Nothing else in the testbench may call `execute_model()`. A second caller would advance the same static state and corrupt every later prediction.

### 2. Registered outputs: the output BFM samples one edge later
The Execute outputs (`aluout`, `pcout`, `dr`, `W_Control_out`, `Mem_Control_out`, `IR_Exec`, `NZP`, `M_Data`) update after the clock edge where `enable_execute` was high. `execute_out_monitor_bfm` therefore keeps `enable_d1`/`reset_d1` (same technique as P2's `decode_out_monitor_bfm`) and samples at the next edge, so output sample N pairs with input sample N. The in monitor reads at `@(posedge clock)`, before the non-blocking updates of that edge.

`sr1`/`sr2` are latched at the enable edge (`sr1_d1`/`sr2_d1`) so they describe the same instruction as the registered outputs. This is an assumption from the design spec; the first simulation confirms it (see "How to read a failing run").

### 3. Strict compare, no don't-cares
All 10 outputs are compared on every transaction with `===` on 4-state `logic` fields, so an X or Z from the RTL is a mismatch instead of being read as 0. If the model leaves an output unspecified for some instruction (for example `dr` for a store), the first run will show it as a mismatch on that field. Confirm against the spec before masking anything.

### 4. One interface, active at block level and passive at LC3 level
`execute_in_if` uses `inout tri` ports, like `decode_in_if` and `control_in_if`. The same interface is driven by `execute_in_driver_bfm` in the execute bench and tied to `DUT.IR`-style references in the LC3 bench. `execute_out_agent` is passive in both and `initialize()` stops with a fatal if configured `UVM_ACTIVE`. At LC3 level `execute_in_driver_bfm.sv` must still be compiled, because the configuration class holds a `virtual execute_in_driver_bfm` handle. `files_execute.f` lists it.

### 5. The scoreboard keeps two queues
Same reasoning as `control_scoreboard`: expected and actual are buffered and compared whenever both have an entry, so the result does not depend on which monitor fires first. It checks that the transaction numbers match (catches misalignment), prints only the fields that differ, counts mismatches per signal and stops printing after `max_mismatch_prints` (default 20). The analysis-imp suffixes are `_execute_expected` / `_execute_actual`, so `lc3_env_pkg` can import this next to `decode_env_pkg` and `control_env_pkg`.

### 6. Conventions shared with the control and decode packages
- `initialize(environment_path, interface_names[], interface_activity[])` on the env config, which publishes itself under `"execute_env_configuration"`
- agent configs `initialize(activity, agent_path, interface_name)`, published at the agent path under `"configuration"`
- BFM handles fetched with key `"*"` and the interface name (`execute_in_if`, `execute_out_if`)
- `monitored_ap` / `predicted_ap`, class-side monitor with `start_monitoring()` in the BFM, separate sequencer class
- test class `test_top`, `ITEMS` / `VERBOSITY` Makefile variables, `+EXEC_ITEMS` plusarg

---

## Verification done here
- A run on Questa 2026.1 passes 1000 of 1000 comparisons with 0 mismatches, and both covergroups reach 100%.
- All packages, the bench and the test were syntax and elaboration checked with **slang** against the Accellera **UVM** library. The only diagnostic is slang rejecting `virtual <bfm>` handles for BFMs that take an interface port; the control and decode packages get the identical message and Questa accepts the pattern. A deliberately misspelled field was caught, so the check is live.
- The port names in `hdl_top` and the `LC3` net names in the snippet were compared against `Execute.v` and `TopLevelLC3.v`.
- **Not done:** the LC3-level wiring in `project_benches/lc3/` has not been simulated. It compiles against the real `TopLevelLC3.v` net names, but it needs the group's merged LC3 bench to run.
