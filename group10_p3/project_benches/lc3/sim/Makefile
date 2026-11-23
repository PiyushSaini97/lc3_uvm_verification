# test_top (default), lc3_base_test, lc3_alu_test, lc3_mem_test, lc3_ctrl_test, lc3_sweep_test
TESTNAME  ?= test_top
# UVM_HIGH prints every monitored transaction and every scoreboard match.
VERBOSITY ?= UVM_MEDIUM
# Instruction fetches before the test stops (empty = the test's default:
# 5000, or 37457 for lc3_sweep_test), and drain cycles after that.
INSTRS    ?=
DRAIN     ?= 20
# test_top only: snippet weights RANDOM,HAZARD,BRANCH,CONST,JUMP,MEM_CORNER,INDIRECT (empty = defaults).
MIX       ?=
# Simulation seed. regress.sh passes a fixed one per run so failures can be rerun.
SEED      ?= random
# Every batch run saves <TESTNAME>_<SEED>.ucdb with that string as its test name,
# which is what the test plan's "test" links match (test_top*, lc3_alu_test*, ...).
RUN_NAME   = $(TESTNAME)_$(SEED)
TEST_PLAN  = lc3_test_plan
MERGED     = sim_and_testplan_merged.ucdb

# -timescale gives files without a timeunit the same 1ns/1ps that several
# verification_ip packages declare; without it Questa reports vsim-3009.
QRUN_COMMON = qrun -64 -coverage -classdebug -uvmcontrol=all -msgmode both \
              -suppress 8887 -timescale 1ns/1ps -l $(RUN_NAME).log \
              -f files.f +acc -sv_seed $(SEED) \
              +UVM_TESTNAME=$(TESTNAME) +UVM_VERBOSITY=$(VERBOSITY) \
              $(if $(INSTRS),+LC3_INSTRS=$(INSTRS)) +LC3_DRAIN=$(DRAIN) $(if $(MIX),+LC3_MIX=$(MIX)) \
              -top hdl_top -top hvl_top

lc3_debug:
	$(QRUN_COMMON) -gui -onfinish stop \
	     -do "set IterationLimit 140000; set NoQuitOnFinish 1; run 0; do wave.do; run -a;"

lc3_batch:
	$(QRUN_COMMON) \
	     -do "set NoQuitOnFinish 1; run -a; \
	          coverage attribute -name TESTNAME -value $(RUN_NAME); \
	          coverage save $(RUN_NAME).ucdb; quit -f;"

# Clean, then one batch run (first line of regress.sh).
lc3_cli: clean lc3_batch

# Test plan (Excel "XML Spreadsheet 2003" export of lc3_test_plan.xls) + every run.
merge_coverage:
	rm -f $(MERGED) $(TEST_PLAN).ucdb
	xml2ucdb -format Excel ./$(TEST_PLAN).xml ./$(TEST_PLAN).ucdb
	vcover merge -stats=none -strip 0 -totals $(MERGED) ./*.ucdb

# HTML report of the merged database, test plan included (covhtmlreport/index.html).
coverage_report:
	vcover report -html -details -output covhtmlreport $(MERGED)

view_coverage:
	vsim -viewcov ./$(MERGED)

clean:
	rm -rf work qrun.out transcript *.log *.wlf qwave.db *.ucdb certe_dump.xml design.bin covhtmlreport
