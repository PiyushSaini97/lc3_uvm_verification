TESTNAME  = test_top
# Per-cycle MATCH/monitor messages are UVM_HIGH; the default keeps the transcript
# readable. Use:  make memaccess_debug VERBOSITY=UVM_HIGH   to see every cycle.
VERBOSITY ?= UVM_MEDIUM
# Items per sequence (test_top runs 3 sequences: fsm, random, fsm).
ITEMS     ?= 200

memaccess_debug:
	qrun -64 -gui -coverage -onfinish stop -classdebug -uvmcontrol=all \
	     -msgmode both -suppress 8887 -l run.log \
	     -f files.f +acc -sv_seed random \
	     -do "set IterationLimit 140000; set NoQuitOnFinish 1; run 0; do wave.do; run -a;" \
	     +UVM_TESTNAME=$(TESTNAME) +UVM_VERBOSITY=$(VERBOSITY) +MEMACCESS_ITEMS=$(ITEMS) \
	     -top hdl_top -top hvl_top

memaccess_batch:
	qrun -64 -coverage -classdebug -uvmcontrol=all -msgmode both -suppress 8887 -l run.log \
	     -f files.f +acc -sv_seed random \
	     +UVM_TESTNAME=$(TESTNAME) +UVM_VERBOSITY=$(VERBOSITY) +MEMACCESS_ITEMS=$(ITEMS) \
	     -top hdl_top -top hvl_top \
	     -do "run -a; quit -f;"
	@$(MAKE) --no-print-directory coverage

# Merge every per-seed database into one, plus a text report.
#
# Do NOT put `coverage save <file>` in the -do string. qrun injects its own
#     -do "coverage save -onexit test_top_$$Sv_Seed.ucdb"
# ahead of ours, and that is the save that actually lands; an explicit `coverage
# save` in our -do reports "saved successfully" and produces no file, with a
# relative path or an absolute one. Measured on Questa 2026.1: three runs, no
# memaccess_coverage.ucdb, while test_top_<seed>.ucdb appeared every time.
#
# Merging the per-seed files is what P3 asks for anyway ("UCDB file containing
# merged coverage results"), and running memaccess_batch a few times before
# `make coverage` accumulates seeds into one database.
coverage:
	vcover merge -out memaccess_coverage.ucdb test_top_*.ucdb
	vcover report -details -output memaccess_coverage.txt memaccess_coverage.ucdb
	@echo "merged $$(ls test_top_*.ucdb | wc -l) seed(s) -> memaccess_coverage.ucdb + memaccess_coverage.txt"

clean:
	rm -rf work qrun.out transcript *.log *.wlf qwave.db *.ucdb run.log certe_dump.xml design.bin memaccess_coverage.txt

.PHONY: memaccess_debug memaccess_batch coverage clean
