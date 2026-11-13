# LC3 Project 3: Mem Access stage UVM packages

This covers the Mem Access part of the LC3 bench (P3 slides 4, 7 and 8), plus a standalone MemAccess block bench.

| Package | Location | Role |
|---|---|---|
| `memaccess_in_pkg` | `verification_ip/interface_packages/memaccess_in_pkg` | Agent for MemAccess's 5 inputs. **Active** in the memaccess bench, **passive** in the LC3 bench |
| `memaccess_out_pkg` | `verification_ip/interface_packages/memaccess_out_pkg` | Passive agent that watches MemAccess's 4 outputs |
| `memaccess_env_pkg` | `verification_ip/environment_packages/memaccess_env_pkg` | Env config, predictor (`mem_access_model`), scoreboard and environment |
| memaccess block bench | `project_benches/memaccess` | Runs MemAccess on its own, like the P2 decoder bench and the control bench |

LC3-level integration pieces, to merge into the LC3 bench later:

- `project_benches/lc3/tb/testbench/hdl_top_memaccess_snippet.sv`: interfaces, BFMs and `uvm_config_db` sets.
- `project_benches/lc3/sim/files_memaccess.f`: lines to add to `files.f`, in compile order.
- `project_benches/lc3/integration/lc3_env_memaccess_hookup.svh`: how `lc3_env_configuration` and `lc3_environment` instantiate and initialize the memaccess environment.

As in the control package, the LC3 snippet connects to the nets of the unencrypted `LC3` top rather than reaching into the encrypted `MemAccess` instance. Check that `` `define LC3_TOP_PATH DUT `` matches the instance name you give `LC3` in `hdl_top`, and do not define it twice if the control snippet already did.

---

## Running the memaccess block bench

```
cd project_benches/memaccess/sim
make memaccess_batch                        # batch + merged coverage (~20 s)
make memaccess_debug                        # GUI + wave.do, like p2_debug (~12 min)
make memaccess_debug VERBOSITY=UVM_HIGH     # print every cycle (MATCH lines, monitors)
make memaccess_batch ITEMS=1000             # items per sequence (default 200)
make coverage                               # merge all test_top_*.ucdb seeds again
```

Use `memaccess_batch` for regressions: measured on grendel it finishes in about 20 seconds against nearly 12 minutes for the GUI target, which carries `+acc` and transaction recording. `memaccess_batch` ends by merging coverage into `memaccess_coverage.ucdb` and writing `memaccess_coverage.txt`. Running it several times and then `make coverage` merges all the seeds into one database.

`rtl/` holds `Mem_Access.v` and `data_defs.v` from `LC3_veloce_encrypted.zip`. The directory layout is the same as the decoder and control benches, so `files.f` reaches `verification_ip/` with the same `../../../` paths. The archive includes the course's `lc3_prediction_pkg`, unchanged, so it builds on its own after extraction. If you merge it into a tree that already has that package, keep one copy; they are identical.

After changing files, run `make clean` before the next run so qrun's incremental session (`qrun.out`) rebuilds everything.

**What a passing run looks like** (measured on Questa 2026.1, grendel, `ITEMS=200`):

```
--------------- MEMACCESS SCOREBOARD ---------------
  Comparisons made               : 2279
  Matches                        : 2279
  Mismatches                     : 0
  Misaligned comparisons         : 0
  Skipped (undefined inputs)     : 0
  Expected left unmatched        : 0
  Actual left unmatched          : 0
----------------------------------------------------
memaccess_in  coverage = 100.00%
memaccess_out coverage = 100.00%
UVM_ERROR : 0   UVM_WARNING : 0   UVM_FATAL : 0
```

No "Mismatches by signal" table appears on a passing run; it only prints when something failed. The illegal bins stay empty, so MemAccess never drove an X onto a memory control line. The test is about 2,200 clock cycles, roughly 22 µs of simulated time.

**How to read a failing run:** each mismatch prints only the signals that differ, with expected and actual values, and the report's "Mismatches by signal" table says which output is wrong.

- Mismatches only in specific states, such as `Data_addr` wrong whenever `M_Control` is 1: that is a real MemAccess bug of the kind P3 asks you to find. Note the cycle number and open the waves at that time.
- Mismatches on **every** cycle of one state, on three signals at once, usually mean a modelling problem rather than an RTL one. That is what the first run found; see "Two defects found on the first run" below.

---

## The MemAccess block, and why this bench looks different

MemAccess is the simplest stage in the LC3 and the only one with **no clock and no reset port**:

```verilog
module MemAccess( mem_state, M_Control, M_Data, M_Addr, memout, Data_addr, Data_din, Data_dout, Data_rd);
```

It is purely combinational. Everything it drives is a function of the five inputs in the same instant. From the LC3 Design Spec and `mem_access_model()`:

| `mem_state` | Meaning | `Data_rd` | `Data_din` | `Data_addr` |
|---|---|---|---|---|
| 0 | read | 1 | 0 | `M_Control ? Data_dout : M_Addr` |
| 1 | first read of LDI/STI (fetch the pointer) | 1 | 0 | `M_Addr` |
| 2 | write | 0 | `M_Data` | `M_Control ? Data_dout : M_Addr` |
| 3 | idle | `z` | `z` | `z` |

`memout` is `Data_dout` forwarded unchanged, in **every** state including idle.

`M_Control` selects the address source: 0 for a direct access (LDR, STR), 1 for the second access of an indirect one (LDI, STI), where the address is the pointer that the `mem_state == 1` access just read back on `Data_dout`.

---

## Design decisions and why

### 1. One transaction per clock cycle
The block has no clock, but it sits in a clocked system and every other stage's bench samples on a clock. Both monitors sample on every rising edge where reset is low, and every post-reset cycle is a transaction, idle cycles included. There is no qualifying enable, unlike P2's `decode_out`, which waited for `enable_decode`. Idle cycles are exactly where the tri-state behaviour lives, so they have to be checked too.

### 2. Inputs and outputs are sampled on the same edge
The outputs are a combinational function of the inputs in the same cycle, so input sample N and output sample N must describe the same cycle. Reading at `@(posedge clock)` gets the values that were stable through the cycle that just ended, because the registers feeding MemAccess (Execute's `pcout` and `M_Data`, the Controller's `mem_state`) update with non-blocking assignments later in the same time step. This is the same technique as P2's BFMs, so it stays emulation-friendly.

There is no one-cycle delay to tune here. If the first LC3-level run shows a constant one-cycle shift, the cause is upstream of this block, not in it.

### 3. No checks during reset
MemAccess has no reset of its own. While reset is high the blocks feeding it hold X, which says nothing about this block, so nothing is sampled. Both monitors only restart their cycle numbering, and the scoreboard checks that the two cycle counts agree, which catches stream misalignment.

Unlike `control`, there is no priming step: see decision 6.

### 4. 4-state (`logic`) transactions with `===` compares
This matters more here than anywhere else in the bench. The design drives `Data_addr`, `Data_din` and `Data_rd` to **`z`** in the idle state, so **Z is an expected value, not an error**. With 2-state `bit` fields, as P2 used, an expected `z` and an actual `x` would both become 0 and the comparison would pass. With `logic` fields and `===`, an expected `z` matches only an actual `z`.

Keeping the compare strict is what exposed defect 1 below. A looser compare would have passed silently and left the idle state unverified.

### 5. The scoreboard keeps two queues
Both monitors fire on the same edge, and the simulator may run the `memaccess_out` monitor before the `memaccess_in` monitor → predictor chain. The scoreboard buffers both streams and compares whenever both have an entry, so the result does not depend on event ordering. It also checks that the two cycle numbers match, prints only the fields that differ, and counts mismatches per signal for the final report. Printing stops after `max_mismatch_prints` (default 20), because a combinational bug repeats on every cycle in that state.

The analysis-imp suffixes are `_memaccess_expected`/`_memaccess_actual` rather than `_expected`/`_actual`. The macro declares classes at package scope, and `lc3_env_pkg` will import `decode_env_pkg`, `control_env_pkg` and `memaccess_env_pkg` together.

### 6. `mem_access_model()` is a pure function, so the predictor is simple
`controller_model()` keeps `static` state between calls, which forces the control package's start-up step, its "only one caller" rule and its fatal on mid-test reset. `mem_access_model()` keeps none: it is a plain combinational function. So this predictor has no priming, no ordering constraints, and other components may call the same model if they ever need to.

### 7. Cycles with undefined inputs are kept but not compared
`mem_access_model()` takes 2-state `bit` arguments, so an x or z on an input silently becomes 0 inside it, while the RTL propagates x. Comparing those cycles would report mismatches that say nothing about the design.

When an input the model actually reads in the current state is undefined, the predictor still emits a transaction, so the two streams stay one-for-one, but marks it `dont_care`; the scoreboard skips the comparison and counts it separately. Which inputs are read depends on the state:

| State | Inputs that must be defined |
|---|---|
| any | `Data_dout` — `memout` forwards it unchanged, idle included |
| 3 (idle) | nothing else |
| 1 | `M_Addr` |
| 0 | `M_Control`, then `M_Addr` if direct |
| 2 | `M_Control` and `M_Data`, then `M_Addr` if direct |

In the block bench every input is always driven, so the Skipped count is 0. This matters only at LC3 level, in the cycles after reset before the first instruction has reached Execute. **If the LC3 run shows a large Skipped count, that is worth investigating** — it means something upstream is leaving X on the memory datapath for longer than startup.

### 8. The monitors use the proxy (push) pattern
The monitor hands a handle to itself to its BFM in `connect_phase`, and the BFM calls `proxy.notify_transaction(...)` with the sampled values. This matches `control_in_pkg`/`control_out_pkg` and the UVMF convention. P2's monitors used the pull-style `bfm.monitor()` task instead.

### 9. Coverage aimed at the block's jobs
- **`memaccess_in_coverage`:**
  - every `mem_state`, and `mem_state × M_Control` for the three active states (idle is ignored: `M_Control` is a don't-care there)
  - whole-instruction FSM sequences: `3→0→3` LD/LDR, `3→2→3` ST/STR, `3→1→0→3` LDI, `3→1→2→3` STI, with `[*1:8]` repetition so memory wait states are allowed
  - corner values (`0x0000`, `0xFFFF`) and halves of the range on `M_Addr`, `M_Data` and `Data_dout`
  - indirect accesses crossed with the pointer's value class, so the forwarded address is seen at its corners
- **`memaccess_out_coverage`:**
  - read / write / tri-stated on `Data_rd`
  - value classes on `Data_addr`, `Data_din` and `memout`
  - each direction crossed with each class of address
  - **illegal bins** for an x on `Data_addr`, `Data_din` or `Data_rd`. These are bug detectors, not coverage targets: no `mem_state` can ask this block to drive a memory control line to an unknown value. If one fires during LC3 integration and it turns out to be a reset tail rather than a real bug, change that line to `ignore_bins` and say so in the test plan.

Coverpoints sample the transaction's classification helpers (`rd_class()`, `word_class()`) rather than the raw fields, because a coverpoint bin cannot match an x or z value and this block's idle state legitimately produces z.

### 10. Two sequences, because one cannot do both jobs
`memaccess_in_random_sequence` randomises every field on every cycle. That fills the state and state × control bins fast and reaches input combinations the Controller would never produce — legitimate here, since the block is stateless and any vector is a fair question to ask of it. But a random walk essentially never produces `3→1→0→3` in order, so it cannot close the FSM sequence bins.

`memaccess_in_fsm_sequence` walks whole memory operations the way the Controller does, holding each state for a random 1–3 cycles to imitate wait states. `test_top` runs fsm, then random, then fsm.

---

## Three defects found on the first runs

None were in the RTL. Recorded here because the first is a defect in a **provided** file that every group will hit, and the other two are tool and language traps worth knowing.

### 1. `mem_access_model()` cannot return the tri-state it assigns

`lc3_prediction_pkg/src/mem_access_model.svh` assigns `16'hzzzz` and `1'bz` for `mem_state == 3`, but its output formals are declared `output bit` — a **2-state** type. SystemVerilog converts z to 0 at that assignment, inside the function, so the caller receives `0x0000` / `0` no matter how it declares its own variables. The z is destroyed before the function returns.

Run 1 result: **885 mismatches out of 2269 comparisons**, on `Data_addr`, `Data_din` and `Data_rd` together, expected `0x0000`/`0` against the RTL's `0xzzzz`/`z`. The `bin idle` count was also exactly 885 — one mismatch per idle cycle, no more and no less. `memout` had zero mismatches, because the model forwards `Data_dout` and never drives it to z.

**The RTL is correct and the model's intent is correct; only the return type is wrong.** `memaccess_predictor` therefore restores the intended z for `mem_state == 3` rather than relaxing the comparison, so idle cycles stay strictly checked.

Worth a forum post: the fix in the provided file would be `output logic` on the four outputs. Any group whose scoreboard uses 2-state fields will pass this without noticing, because their expected 0 would compare equal to a z that was also flattened to 0.

### 2. `dist ... := ` on a range almost never produces the corners

The stimulus had `dist { 16'h0000 := 1, 16'hFFFF := 1, [16'h0001:16'hFFFE] := 8 }`. With `:=` the weight applies to **every value in the range**, so the range carries 65534 x 8 = 524272 against 1 for each corner — the corners occur about once in 524274 draws, not one in ten. `:/` divides the weight across the range, which is what was meant.

Run 1 result: `bin max` empty on `M_Addr`, `M_Data` and `Data_dout`; `bin zero` showing exactly 2 hits, both from the driver's reset values rather than from randomization. That pulled `memaccess_in` down to **84.38%** and `memaccess_out` to **65.00%**, including the `active_addr` cross at 33.33%.

This also exposed a weakness in how this package was checked before the first run: the Python coverage model hard-coded the *intended* 10/10/80 split instead of the semantics of `:=`, so it reported every bin reachable. A model of what you meant cannot catch a mistake in what you wrote. The model now implements both forms, reproduces the exact set of empty bins from run 1 under `:=`, and shows them all closing under `:/`.

### 3. `coverage save` in a qrun `-do` string is silently ignored

qrun injects its own `-do "coverage save -onexit test_top_$Sv_Seed.ucdb"` ahead of the one in the Makefile. That `-onexit` save is the one that lands. An explicit `coverage save <file>` in our `-do` prints "Coverage database has been saved successfully" and produces no file — with a relative path or an absolute one. Three runs, no `memaccess_coverage.ucdb`; `test_top_<seed>.ucdb` present every time.

The Makefile now lets qrun save per-seed and merges afterwards with `vcover merge`, which is what P3 asks for anyway ("UCDB file containing merged coverage results"). Worth knowing at LC3 level, where the group's `regress.sh` has to produce exactly that file.

## LC3 integration: two wiring traps

Both are in `hdl_top_memaccess_snippet.sv`, and both would produce a bench that compiles and then mismatches on every active cycle.

1. **`M_Control` is not `DUT.M_Control`.** `TopLevelLC3.v` line 29 declares `wire M_Control;` and never connects it; the instance takes `.M_Control(Mem_Control_out)`. Wiring the interface to `DUT.M_Control` would sample a floating net.
2. **`M_Addr` is not a net called `M_Addr`.** The instance takes `.M_Addr(pcout)`, Execute's `pcout` output. There is no `M_Addr` net in `LC3`.

The full port-to-net map is in the snippet's header comment.

---

## Verification done here

- The **memaccess block bench** (`hdl_top`, `hvl_top`, `memaccess_test_pkg`, all three packages) was compiled and elaborated with **slang** (pyslang 12.1) against a UVM stand-in and the real `Mem_Access.v` port list. **No errors and no warnings point at any project file.**
- The port-to-net map in the LC3 snippet was checked against the real `TopLevelLC3.v` line by line; that is where the two traps above came from.
- The predictor's call into `mem_access_model()` was checked for argument order and output field mapping against the model's declaration, and again by running both sides of the comparison through a transcription of the model.
- **Simulated on Questa 2026.1** (grendel), `make memaccess_debug` and `make memaccess_batch`: compiles with 0 errors and 0 warnings, 2269 comparisons, no misalignment, nothing left unmatched, no skipped cycles and no illegal-bin hits. Run 1 found the two defects above; both are fixed here, and the cycle model that reproduces run 1's failure signature shows both covergroups closing afterwards.
- **Coverage reachability was re-simulated** against the real `dist` semantics, 20 seeds, default `ITEMS=200`: every bin in both covergroups is reachable, and the predictor agrees with the design on every cycle including idle. A run is about 2,200 clock cycles, roughly 22 µs of simulated time.
- The only remaining diagnostic is slang rejecting `virtual <bfm>` handles for BFMs that take an interface port. P2's working `decode_in_pkg` and the control package get the identical message, and Questa and UVMF accept this pattern.
- **Still to confirm on your machine:** the post-fix numbers. Run 1 was taken before the two fixes; re-run and check the scoreboard reads 0 mismatches and both covergroups read 100%.
