TESTNAME  = test_top
# Per-cycle MATCH/monitor messages are UVM_HIGH; the default keeps the transcript
# readable. Use:  make control_debug VERBOSITY=UVM_HIGH   to see every cycle.
VERBOSITY ?= UVM_MEDIUM
# Instructions per sequence (test_top runs 5 sequences).
ITEMS     ?= 1000

control_debug:
	qrun -64 -gui -coverage -onfinish stop -classdebug -uvmcontrol=all \
	     -msgmode both -suppress 8887 -l run.log \
	     -f files.f +acc -sv_seed random \
	     -do "set IterationLimit 140000; set NoQuitOnFinish 1; run 0; do wave.do; run -a;" \
	     +UVM_TESTNAME=$(TESTNAME) +UVM_VERBOSITY=$(VERBOSITY) +CTRL_ITEMS=$(ITEMS) \
	     -top hdl_top -top hvl_top

control_batch:
	qrun -64 -coverage -classdebug -uvmcontrol=all -msgmode both -suppress 8887 -l run.log \
	     -f files.f +acc -sv_seed random \
	     +UVM_TESTNAME=$(TESTNAME) +UVM_VERBOSITY=$(VERBOSITY) +CTRL_ITEMS=$(ITEMS) \
	     -top hdl_top -top hvl_top \
	     -do "run -a; coverage save control_coverage.ucdb; quit -f;"

clean:
	rm -rf work qrun.out transcript *.log *.wlf qwave.db *.ucdb run.log certe_dump.xml design.bin
