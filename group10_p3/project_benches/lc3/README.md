# LC3 top-level bench (`project_benches/lc3`)

Same layout as `project_benches/decoder` and `project_benches/control`, extended to the full LC3. It uses your `verification_ip/` tree **unchanged**.

```
project_benches/lc3/
  rtl/             all 8 files from LC3_veloce_encrypted.zip (TopLevelLC3.v is the DUT top)
  sim/             Makefile, files.f, wave.do
  tb/testbench/    hdl_top.sv, hvl_top.sv
  tb/sequences/    lc3_sequence_pkg.sv + src/: the stimulus (see "Stimulus" below)
  tb/tests/        lc3_test_pkg.sv + src/: lc3_base_test and the tests derived from it
```

Put `project_benches/` next to `verification_ip/`; `files.f` uses the same `../../../verification_ip` paths as the other benches.

## Running it

```
cd project_benches/lc3/sim
make lc3_debug                        # GUI, loads wave.do, runs test_top to the end
make lc3_batch                        # batch, saves <TESTNAME>.ucdb
make lc3_batch TESTNAME=lc3_sweep_test   # any test from "Tests" below
make lc3_debug INSTRS=20000           # instruction fetches before stopping (default per test)
make lc3_batch MIX=10,60,10,5,5,5,5   # test_top snippet weights (see "Stimulus")
make lc3_debug VERBOSITY=UVM_HIGH     # print every transaction and match
make clean                            # run this after changing any file
```

## What the waveform shows (`wave.do`)

Groups follow the instruction flow:

| Group | Contents |
|---|---|
| LC3 ports | `pc`, `instrmem_rd`, `Instr_dout`, `complete_instr`, `Data_addr`, `Data_rd`, `Data_din`, `Data_dout`, `complete_data`, and the bench's `dmem_request` |
| Pipeline | the five enables, `IR`, `IR_Exec`, both `npc`s, `aluout`, `pcout`, `memout`, `br_taken`, `NZP`, `psr`, `mem_state` |
| Bypass | the four bypass signals |
| Register file | `R0`–`R7` |
| `imem_if`, `dmem_if` | the memory agents' interfaces |
| `fetch_in_if` … `writeback_out_if` | one group per stage interface: exactly what each passive agent samples |

`wave.do` starts with `onerror {resume}`, so if Questa can't show a signal, for example because it sits inside encrypted RTL, it skips it and keeps going. The register file group is the one most likely to be affected.

## How the bench is wired (`hdl_top.sv`)

- **DUT:** `LC3 DUT(...)` from `TopLevelLC3.v`.
- **Active agents: instruction and data memory only.**
  - `imem_if` connects `request` ← `instrmem_rd`, `address` ← `pc`, and drives `Instr_dout` and `complete_instr`. `read` is tied to 1 and `write_data` to 0, because instruction memory is read-only.
  - `dmem_if` connects `read` ← `Data_rd`, `address` ← `Data_addr`, `write_data` ← `Data_din`, and drives `Data_dout` and `complete_data`.
  - **`request` is derived:** the LC3 has no data-memory request pin, so `dmem_request` is 1 whenever `DUT.mem_state` is 0 (read), 1 (indirect read) or 2 (write), and 0 when idle (3).
- **Passive agents: all six stages.** Each stage interface is tied to the nets that connect to that stage's ports *in the LC3 top module*, for example `taddr` ← `DUT.pcout`, `Mem_Bypass_Val` ← `DUT.memout`, `IMem_dout` ← `Instr_dout`. Those nets are declared in the unencrypted `TopLevelLC3.v`, so nothing reaches into an encrypted module.
- **BFM registration:** every BFM is registered under the interface name that `lc3_env_configuration::initialize()` passes down (`fetch_in_if`, …, `imem_if`, `dmem_if`).

## Tests (`tb/tests`)

Every test is `lc3_base_test` plus factory overrides in `set_overrides()`. The environment, agents and virtual sequence never change; only the stimulus does.

| Test | Override | Stimulus | Default fetches |
|---|---|---|---|
| `lc3_base_test` | none | every word a randomized `imem_transaction` (any legal encoding, 12 opcodes uniform) | 5000 |
| `test_top` (default) | `imem_responder_sequence` → `lc3_program_responder_sequence` | coverage-directed snippets from `lc3_program_generator` | 5000 |
| `lc3_alu_test` | `imem_transaction` → `imem_alu_transaction` | ADD/AND (both modes), NOT only | 5000 |
| `lc3_mem_test` | `imem_transaction` → `imem_mem_transaction` | LD/LDI/LEA/LDR/ST/STI/STR only | 5000 |
| `lc3_ctrl_test` | `imem_transaction` → `imem_ctrl_transaction` | BR 6 : JMP 1 : ADD/AND/NOT 1 each | 5000 |
| `lc3_sweep_test` | `imem_transaction` → `imem_sweep_transaction` | every legal encoding exactly once, random order | 37457 (9 prologue + 37448) |

All of them:
- build `lc3_env_configuration`, call `initialize("uvm_test_top.env")`, create `lc3_environment` as `env`;
- print the factory (overrides included) at end of elaboration;
- start `lc3_vseq`, which creates both memory responders through the factory and returns after `INSTRS` fetches (prologue included);
- drain `DRAIN` cycles (default 20), then end 1 ns after a falling edge so no memory handshake is half-recorded;
- fail with `UVM_FATAL` from a watchdog if the CPU stops fetching. Drain timing assumes the 10 ns clock in `hdl_top`.

## Stimulus

At LC3 level a test controls only three things: the **instruction stream**, the **data-memory contents** and the **data-memory latency**.

Responders live in the agents' packages, so any bench using the agents gets them:

| Class | Package | Role |
|---|---|---|
| `imem_responder_sequence` | `imem_pkg` | Answers every fetch. First the 9-word prologue, then `fill()`, which by default randomizes a factory-created `imem_transaction`. Latency is always 0 (the IMEM driver BFM forbids waits) |
| `dmem_responder_sequence` | `dmem_pkg` | Data memory: about 60% of contents are corner values (`0000 0001 7FFF 8000 FFFE FFFF`); latency 1–3 cycles; remembers stores |

What a test selects lives in `tb/sequences/lc3_sequence_pkg`:

| Class | Role |
|---|---|
| `lc3_vseq` | Virtual sequence every test starts |
| `lc3_program_responder_sequence` | `imem_responder_sequence` whose `fill()` takes the next word from `lc3_program_generator` |
| `lc3_program_generator` | Builds the instruction stream from coverage-targeted snippets; reads `+LC3_MIX` |
| `lc3_isa` | Encoders for the 12 instructions, plus a legality check run on every generated word |
| `imem_alu_transaction`, `imem_mem_transaction`, `imem_ctrl_transaction` | `imem_transaction` with one extra constraint on `opcode` |
| `imem_sweep_transaction` | `pre_randomize()` takes the next index from a static shuffled list of all 37448 encodings; a constraint pins `data` to it. Static because each fetch gets a new object (no `randc`) |

**The stream is the execution order.** This controller never fetches down a wrong path: it stops fetching while a BR or JMP is in flight, then fetches the target. So the order of fetch requests is the order of execution, and the generator can place a producer directly before its consumer, or a `psr` setter directly before a branch. Every fetch gets a fresh word, so a backward branch can't trap the test in a loop.

**Prologue:** `AND Rk,Rk,#0` for all eight registers, then R0 again. Registers are X after reset, and a JMP, LDR or STR through an X register would trip the memory BFMs' "unknown request" `$fatal` checks. The first word equals the IMEM driver BFM's preloaded `0x5020`.

**`test_top` snippets** (default weights in brackets; change them with `MIX=` in the order shown):

| Snippet | What it emits | What it targets |
|---|---|---|
| RANDOM [30] | 1–4 fully random legal instructions | `opcode_cg`, register crosses, `offset_cg`, `field_value_cg`, `sequence_cg` |
| HAZARD [25] | ALU or load producer of `Rd`, 0–2 unrelated fillers, then a consumer reading `Rd` through sr1, sr2 or both (ADD/AND/NOT/LDR/STR/JMP for sr1; ADD/AND/ST/STR/STI for sr2) | `dependency_cg`; in the pipeline, every ALU/memory bypass path |
| BRANCH [15] | Sets `psr` to N, Z or P (`AND #0`, then `NOT` or `ADD #1`), 0–2 NOPs, then BR with any of the 8 conditions and either offset sign | `branch_cg`, `offset_cg`; in the pipeline, every condition under N, Z and P, taken and not taken |
| CONST [8] | Builds `0000/0001/7FFF/8000/FFFE/FFFF` in a register (`0x8000` by 15 doublings), then uses it as an ALU operand or as store data | `alu_mode_cg` immediates; in the pipeline, ALU result and store-data corners |
| JUMP [6] | JMP to `0000/7FFF/8000/FFFE/FFFF`, then PC-relative LEA/LD/ST whose result or address is `0000` or `FFFF` | `jmp_cg`; in the pipeline, PC and address corners 0000/FFFF |
| MEM_CORNER [8] | Base register `0000` or `FFFF`; STR/LDR at the corner and one step across it (wraps); store data is a corner | LDR/STR offsets; in the pipeline, data-address wraparound at 0000/FFFF |
| INDIRECT [8] | LDI/STI, including STI of a corner value | LDI/STI; in the pipeline, both indirect memory-FSM sequences |

All words are legal by construction. `0x0000` is never produced (see `known_dut_bug_c`); the NOP is `BR` with condition `000` and offset 1.

## Instruction coverage (`imem_coverage`)

One coverage component, in the instruction-memory agent (`imem_pkg/src/imem_coverage.svh`), sampling every fetched word. `imem_configuration.has_coverage` (default 1) turns it on, and the agent creates it through the factory, so another model can be dropped in without editing the bench:

```
imem_coverage::type_id::set_type_override(other_coverage::get_type());
```

It sits at the memory agent because that is where every word the stimulus sends is seen, whichever test or sequence produced it. Because fetch order is execution order, the back-to-back groups describe what the pipeline actually ran. The old `decode_in_coverage` has been removed; its covergroups moved here unchanged.

| Covergroup | Bins | What it measures |
|---|---|---|
| `opcode_cg` | 12 | each implemented opcode (JSR/RTI/TRAP have no bins, RESERVED illegal) |
| `alu_mode_cg` | 4 | ADD/AND × register/immediate |
| `destination_cg` | 56 | writer × DR |
| `source1_cg` | 48 | SR1/BaseR reader × SR1 |
| `source2_cg` | 40 | SR2/SR reader × SR2 |
| `branch_cg` | 8 | all BR conditions, `000` included |
| `offset_cg` | 16 | offset user × offset sign |
| `dependency_cg` | 4 | ALU/load producer → next instruction reads it via SR1/SR2 |
| `alu_imm_cg` | 4096 | ADD/AND × DR × SR1 × imm5 |
| `alu_reg_cg` | 1024 | ADD/AND × DR × SR1 × SR2 |
| `not_cg` | 64 | DR × SR |
| `ld_ldi_lea_cg` | 12288 | LD/LDI/LEA × DR × PCoffset9 |
| `ldr_cg` | 4096 | DR × BaseR × offset6 |
| `st_sti_cg` | 8192 | ST/STI × SR × PCoffset9 |
| `str_cg` | 4096 | SR × BaseR × offset6 |
| `br_cg` | 3584 | nzp `001`–`111` × PCoffset9 |
| `jmp_cg` | 8 | BaseR |
| `field_value_cg` | 20+24+108 | opcode × magnitude class of imm5 / offset6 / PCoffset9 (0, 1, 2–3, 4–7 … and the negative mirror, min) |
| `sequence_cg` | 144 | opcode × previous opcode |

`report_phase` prints every group and the average (`IMEM_COVERAGE` in the transcript).

**What closes what.** The nine exhaustive crosses (`alu_imm_cg` … `jmp_cg`, 37448 bins) close in one run of `lc3_sweep_test`; random stimulus needs hundreds of thousands of fetches to get there. `sequence_cg` does not close in the sweep, because JMP has only 8 encodings, so JMP→X pairs are rare; `test_top`, `lc3_base_test` and `lc3_ctrl_test` close it. Merge the UCDBs (`vcover merge`) to see the total.

This is the bench's only coverage. The stage-level covergroups (control, execute, memaccess, writeback) have been removed; the stage scoreboards still check every stage on every cycle.

## Coverage expectations

The snippet generator was mirrored in Python and run through an architectural LC3 model. At 5,000 instructions it hit every bin of the instruction-level groups (`opcode_cg` … `dependency_cg`) on each of three seeds. On the nine exhaustive crosses it reaches about 27% at 5,000 fetches, which is why `lc3_sweep_test` exists. The sweep's index-to-encoding table was checked in Python: 37448 distinct legal words, one per cross bin.

**Not targets** (documented in the test plan):

| Bins | Why |
|---|---|
| `opcode_cg` JSR, RTI, TRAP | Not implemented by this LC3, so they have no bins |
| `opcode_cg` RESERVED | `illegal_bins`: fetching it is an error |
| BR `000` with offset 0 (`0x0000`) | Excluded on purpose by `known_dut_bug_c`, so `br_cg` covers nzp `001`–`111` only |
| `field_value_cg` bare coverpoints | `option.weight = 0`; only its three crosses count |

## Regression and test plan (`sim/regress.sh`)

```
cd project_benches/lc3/sim
./regress.sh
```

It runs every test with a fixed seed (`make lc3_cli` cleans first, then `make lc3_batch` for the rest). Then it merges all the UCDBs with the test plan, writes an HTML report, and opens the merged database in the coverage viewer.

- Each batch run saves `<TESTNAME>_<SEED>.ucdb` and `<TESTNAME>_<SEED>.log`, and records `<TESTNAME>_<SEED>` as the UCDB test name. The plan's `test` rows link to `test_top*`, `lc3_alu_test*` and so on; the checker rows link to `*test*`, so every run counts.
- A test whose run had any `UVM_ERROR` raises one `$error` in `report_phase`, so Questa marks that test failed in its UCDB.
- `lc3_test_plan.xls` is the plan to edit. `xml2ucdb` reads `lc3_test_plan.xml`, the same sheet saved from Excel as **XML Spreadsheet 2003**. Re-export it after every edit.
- Single steps: `make merge_coverage`, `make coverage_report` (writes `covhtmlreport/index.html`), `make view_coverage`. To repeat one run, use `make lc3_batch TESTNAME=lc3_mem_test SEED=1111`.

## Results to read at the end of the transcript

- `IMEM_COVERAGE`: instruction coverage per covergroup and the average.
- Each stage environment's scoreboard summary.
- `LC3_MEMORY_SUMMARY`: instruction- and data-memory pairs checked. The LC3 scoreboard fails if no instruction or data accesses happened, or if any are left unpaired.
- The UVM report counts by ID.

## Compile check done here

The full bench (`hdl_top`, `hvl_top`, `lc3_test_pkg` and every package in `verification_ip/`) was compiled and elaborated with slang against UVM 1.1d and the real RTL port lists. It produced no errors or warnings on bench or `verification_ip` files.

The one exception is the known slang rule against `virtual` handles to BFMs that take an interface port. Questa accepts that pattern; it's the one your other benches already use. A deliberately misspelled `DUT.` net was rejected, confirming that the hierarchical wiring is checked.

No simulation was run here, because the RTL is encrypted for Questa.
