# LC3 Project 3: Control stage UVM packages

This covers the Control part of the LC3 bench (P3 slides 4, 7 and 8), plus a standalone control block bench:

| Package | Location | Role |
|---|---|---|
| `control_in_pkg` | `verification_ip/interface_packages/control_in_pkg` | Agent for the controller's 7 inputs. **Active** in the control bench, **passive** in the LC3 bench |
| `control_out_pkg` | `verification_ip/interface_packages/control_out_pkg` | Passive agent that watches the controller's 11 outputs |
| `control_env_pkg` | `verification_ip/environment_packages/control_env_pkg` | Env config, predictor (`controller_model`), scoreboard and environment |
| control block bench | `project_benches/control` | Runs the controller on its own, like the P2 decoder bench |

LC3-level integration pieces, to merge into your LC3 bench later:

- `project_benches/lc3/tb/testbench/hdl_top_control_snippet.sv`: interfaces, BFMs and `uvm_config_db` sets.
- `project_benches/lc3/sim/files_control.f`: lines to add to `files.f`, in compile order.
- `project_benches/lc3/integration/lc3_env_control_hookup.svh`: how `lc3_env_configuration` and `lc3_environment` instantiate and initialize the control environment.

The LC3 snippet connects to the nets of the unencrypted `LC3` top (`DUT.IR`, `DUT.IR_Exec`, `DUT.Instr_dout`, ...) rather than reaching into the encrypted `Ctrl` instance. Check that `` `define LC3_TOP_PATH DUT `` matches the instance name you give `LC3` in `hdl_top`.

---

## Running the control block bench

```
cd project_benches/control/sim
make control_debug                         # GUI + wave.do, like p2_debug
make control_batch                         # batch, saves control_coverage.ucdb
make control_debug VERBOSITY=UVM_HIGH      # print every cycle (MATCH lines, monitors)
make control_batch ITEMS=1000              # instructions per sequence (default 200)
```

`rtl/` holds `Controller_Pipeline.v` and `data_defs.v` from `LC3_veloce_encrypted.zip`. The directory layout is the same as the decoder bench, so `files.f` reaches `verification_ip/` with the same `../../../` paths. The archive includes the course's `lc3_prediction_pkg`, unchanged, so it builds on its own after extraction. If you merge it into a tree that already has that package, keep one copy; they are identical.

After changing files, run `make clean` before the next run so qrun's incremental session (`qrun.out`) rebuilds everything.

**What a passing run looks like:** at the end of the transcript, the `CONTROL SCOREBOARD` report shows Mismatches 0, Misaligned 0 and nothing left unmatched. The predictor's report line says `start-up step on reset cycle: yes`. With the default `ITEMS=50` the comparison count is several hundred cycles.

**How to read a failing run:** each mismatch prints only the signals that differ, with expected and actual values. The report's "Mismatches by signal" table tells you which output is wrong. Two patterns to recognize:

- **Every** comparison mismatches from cycle 0, and the expected values look like the actual ones shifted by one cycle: the controller registers its outputs (see Design decision 2). Delay `control_out_monitor_bfm` by one cycle.
- Mismatches in specific situations only, such as `bypass_mem_2` after an STR or `mem_state` during LDI: those are controller bugs, which is what P3 asks you to find. Note the cycle number and open the waves at that time.

---

## The control bench, and why the driver is reactive

In the decoder bench, `decode_in`'s inputs were independent stimulus: any instruction and npc could be driven at any time. The controller is different. In the LC3, most of its inputs are produced by the rest of the pipeline in response to the controller's own enables:

| Controller input | Produced by | Rule the bench follows (Design Spec) |
|---|---|---|
| `Instr_dout`, `complete_instr` | instruction memory | **synchronous read**: the word at the PC of cycle *t* appears in cycle *t+1* if `enable_fetch` was high in *t* (spec timing diagrams: PC=`3000` in cycle 0 → `Imem[PC]`=`5020` in cycle 1). The PC moves at edges where `enable_updatePC` is high. `complete_instr` is 1 (see "Instruction-memory waits" below) |
| `IR` | Decode | `IR <= Instr_dout` when `enable_decode` |
| `IR_Exec` | Execute | `IR_Exec <= IR` when `enable_execute` |
| `NZP` | Execute | BR → `IR[11:9]`, JMP → `111`, else `000`, latched when `enable_execute`; **goes to `000` when `enable_execute` is low** |
| `psr` | Writeback | updated on each register-file write (`enable_writeback`) |
| `complete_data` | data memory | low for N cycles in each memory state, then high |

Driving these randomly would give the controller input combinations that can't happen in the LC3, such as an `IR_Exec` that never passed through `IR`. The scoreboard would then flag "mismatches" that aren't bugs. So `control_in_driver_bfm` contains a small model of exactly those registers. It is clocked by the controller's own outputs, which it reads through `control_out_if`, the reason the BFM takes both interfaces.

Everything is synchronous `always` blocks plus one `drive()` task, the same emulation-friendly style as P2's driver BFM. The real Decode/Execute/Writeback are not used, so a mismatch points at the controller and nothing else.

**What the sequence controls:** a sequence item, `control_in_stimulus`, is one instruction plus the memory timing it experiences:

- `instr`: a legal instruction, using the same 12 opcodes and encoding rules as P2's `decode_in` (RESERVED excluded)
- `instr_wait`: instruction-memory latency in cycles, forced to 0 unless `allow_instr_wait` is set (see below)
- `data_wait`: data-memory latency in cycles, applied to each memory state
- `wb_psr`: N/Z/P value Writeback reports at the next register write

The first instruction is preloaded on `Instr_dout` during reset, as in the spec's startup diagram. After that, `drive()` returns that instruction for every fetch of the current PC, and returns when the controller moves the PC. The test therefore runs at whatever pace the controller sets, stalls included, and there are no fixed delays to tune. A taken branch also moves the PC, so the next item is simply the branch target. The controller never sees addresses, only the instruction stream.

**Instruction-memory waits are off by default.** The spec says `enable_updatePC` stays low while `complete_instr` is low. `controller_model()` never gates `enable_updatePC` on `complete_instr`; it only marks the fetched word invalid. With waits on, a controller that follows the spec and the predictor disagree by construction. Run 1 showed exactly that: cycles 1–2 had the RTL holding `updatePC` low during a wait while the model expected 1. Those mismatches say nothing about RTL bugs, so `control_in_stimulus.allow_instr_wait` defaults to 0. Data-memory waits (`complete_data`) are fully modeled by the predictor and stay on.

`control_in_stimulus` is separate from `control_in_transaction` on purpose. The transaction is what the monitor observes, one clock cycle of all seven inputs. The stimulus is what the test controls: instructions and timing. They're different things.

**Test plan in `test_top`**, five sequences of `ITEMS` instructions each:

1. **random**: all legal opcodes, uniform. General sanity.
2. **hazard**: ALU/load/store ops with every register field squeezed into R0/R1. Back-to-back dependencies exercise all four bypass paths.
3. **memory**: LD/LDR/LDI/ST/STR/STI with heavier data waits. Exercises the `mem_state` FSM sequences and whole-pipeline stalls.
4. **branch**: BR/JMP mixed with psr-setting ALU ops. Gives `br_taken` both ways and the control-instruction fetch stall.
5. **random** again, so all the behaviors meet back-to-back.

After a run, check coverage: `control_out_coverage` bins show which of these behaviors were actually reached.

---

## Design decisions and why

### 1. One transaction per clock cycle, not per instruction
This is the main difference from P2. `decode_model()` is a pure function, so one instruction in gives one result out. `controller_model()` is not pure. It keeps `static` state between calls: the FE1/FE2/DEC/EXE valid bits, the memory FSM state and `has_been_reset`. It's written to be called once per clock, taking that cycle's inputs and returning that cycle's outputs. So:

- Both monitors emit a transaction on every rising edge where `reset` is low.
- The predictor calls `controller_model()` exactly once per input transaction.
- No `enable` qualifies the samples, unlike `decode_out`, which waited for `enable_decode`. Stall cycles are exactly what the controller must get right, so they have to be checked too.

### 2. Inputs and outputs are sampled on the same edge
In the spec, the controller outputs depend combinationally on its inputs and its state ("sensitive to the changing values of IR, ..., completes, Instr_dout, prev_enables, psr, NZP"). The model is written the same way. Input sample N and output sample N therefore describe the same cycle.

Reading at `@(posedge clock)` gets the values that were stable through the cycle that just ended, because the RTL updates its registers with non-blocking assignments later in the same time step. This is the same technique as P2's BFMs, so it stays emulation-friendly.

> If your first run shows a constant one-cycle shift (every mismatch looks like the expected value one cycle early or late), the RTL controller registers its outputs. In that case, delay the output BFM by one cycle the way P2's `decode_out_monitor_bfm` did with `enable_q`. Nothing else needs to change.

What the RTL shows: `Controller_Pipeline.v` is encrypted, but its plaintext declarations are visible. `mem_state`, the four bypasses and `br_taken` are `reg`s, and the five enables are plain outputs, presumably driven from `reg [4:0] enables`. There are also `state/next_state` and `mem_ctrl_Cstate/Nstate` register pairs. That naming suggests current-state registers with combinational outputs, which fits same-edge sampling, but the encrypted body can't confirm it. Your first simulation will.

### 3. No checks during reset; every post-reset cycle is checked on all outputs
`controller_model()` has no reset input, and its first call is a start-up step: fetch=1, updatePC=0, nothing valid yet. The spec's startup timing diagram puts that step in the **last reset cycle**. `en_fetch` is already high during reset, and the first instruction is decoded in the second cycle after reset, executes in the third and writes back in the fourth.

Earlier versions made the first call on the first post-reset cycle. That put the model one cycle late and caused 4 mismatches in cycles 0–3 of runs 2 and 3, with the RTL one stage ahead in each. The input monitor now keeps the inputs of the last reset cycle and delivers them once, marked `prime`, just before cycle 0. The predictor uses that sample only to take the model's start-up step. It produces no prediction, so nothing from reset is compared, and coverage ignores it too.

This alignment comes from the spec's diagram, not from what the RTL happens to do. If the spec's owner says the diagram is wrong, this is the place to change it.

The predictor's final report states whether the start-up step was taken on a reset cycle. If no reset sample arrives before cycle 0, it warns. A reset after the model has started is a fatal, because the model's state can't be reset.

Reset cycles themselves are not checked. The spec contradicts itself about them: its text says all enables are 0 in reset, but its startup timing diagram shows `en_fetch` and `en_updatePC` high during reset. The bench shouldn't settle that by copying the RTL, and it shouldn't settle it by silently ignoring some signals either. So the decision is explicit: reset cycles are out of scope, and from the first cycle after reset the scoreboard compares all 11 outputs strictly, with no don't-cares.

Both monitors restart their cycle count on reset.

### 4. One interface, active at block level and passive at LC3 level
`control_in_if` uses `inout tri` ports, like P2's `decode_in_if`. That lets the same interface be driven by `control_in_driver_bfm` in the control bench and tied to `DUT.IR`-style hierarchical references in the LC3 bench. Slang accepts both connection styles. This is the same pattern as `decode_in`: active in its own bench, passive at the top.

`control_out_if` keeps `input` ports, because nothing ever drives the controller's outputs except the controller. The `control_out` agent is passive in both benches, and `initialize()` stops with a fatal if anyone configures it `UVM_ACTIVE`.

At LC3 level, `control_in_driver_bfm.sv` must still be compiled even though nothing instantiates it. The configuration class declares a `virtual control_in_driver_bfm` handle, the same situation as `decode_in_driver_bfm`. `files_control.f` already lists it.

### 5. 4-state (`logic`) transactions with `===` compares
P2 used `bit` fields. That's fine for decode, but here an X on `enable_fetch` would turn into 0 and might "pass". With `logic` fields and `===`, an X or Z coming out of the RTL becomes a mismatch against the predictor's clean 0/1 value. Inputs are converted to 2-state only when the predictor calls the model. X inputs are counted and logged at UVM_HIGH.

### 6. The scoreboard keeps two queues
In P2 the actual transaction always came a cycle after the expected one, so "pop expected when actual arrives" worked. Here both monitors fire on the same edge, and the simulator may process the output monitor before the input → predictor chain. The scoreboard buffers both streams and compares whenever both have an entry, so the result doesn't depend on event ordering.

It also does three more things:

- It checks that the two cycle numbers match, which catches stream misalignment.
- It prints only the fields that differ, so a mismatch names the broken signal.
- It counts mismatches per signal for the final report.

Printing stops after `max_mismatch_prints` (default 20) because controller bugs tend to repeat every cycle.

The analysis-imp suffixes are `_control_expected`/`_control_actual` rather than `_expected`/`_actual`. The macro declares classes at package scope, and `lc3_env_pkg` will import `decode_env_pkg` and `control_env_pkg` together.

### 7. Coverage aimed at the controller's jobs (feeds the P3 test plan)
- **`control_in_coverage`:**
  - memory wait states (`complete_instr`/`complete_data` low)
  - `psr` values N/Z/P
  - all 7 branch conditions
  - `NZP × psr` cross, which gives taken and not-taken for each branch type
  - memory opcodes reaching Execute, crossed with `complete_data`
- **`control_out_coverage`:**
  - each `mem_state` value
  - full FSM sequences per instruction class (`3→0→3` LD/LDR, `3→2→3` ST/STR, `3→1→0→3` LDI, `3→1→2→3` STI), allowing wait states
  - `br_taken`
  - all four bypass paths and their legal combinations, with ALU+MEM bypass together as an **illegal bin**
  - whole-pipeline stall during each memory state

These double as bug finders. An empty bin means the tests never exercised that control path. An illegal-bin hit is an RTL bug.

### 8. Rules for any bench using this package
**Only `control_predictor` may call `controller_model()`.** A second caller would advance the same static state and corrupt every later prediction.

Stimulus must never put opcode `4'b1101` (RESERVED) on `Instr_dout`. `decode_lc3_insn()` decodes it every cycle, even when it isn't a valid fetch, and it fires `assert(0)` on RESERVED. `control_in_stimulus` already excludes it.

---

## Verification done here
- The **control block bench** (`hdl_top`, `hvl_top`, `control_test_pkg`, all three packages) was compiled and elaborated with **slang** against the Accellera **UVM** library and the real `Controller_Pipeline.v` port list. No errors or warnings point at any project file.
- The LC3 `hdl_top` snippet was elaborated against the real `TopLevelLC3.v`. All 18 controller connections resolve to real `LC3` nets with matching widths, and a deliberately misspelled net was rejected.
- An earlier run found one real bug, now fixed: a helper named `build()` clashed with `uvm_component::build()`.
- The only remaining diagnostic is slang rejecting `virtual <bfm>` handles for BFMs that take an interface port. P2's working `decode_in_pkg` gets the identical message, and Questa and UVMF accept this pattern.
- **Not done:** simulation. The controller RTL is encrypted for Mentor/Questa and no simulator was available here, so the first run is yours. Section 2 describes the one timing assumption to confirm.
