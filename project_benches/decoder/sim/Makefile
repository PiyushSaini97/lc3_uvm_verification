TESTNAME    = test_top

p2_debug:
	qrun -64 -gui -coverage -onfinish stop -classdebug -uvmcontrol=all \
	     -msgmode both -suppress 8887 -l run.log \
	     -f files.f +acc -sv_seed random \
	     -do "set IterationLimit 140000; set NoQuitOnFinish 1; run 0; do wave.do; run -a;" \
	     +UVM_TESTNAME=$(TESTNAME) +UVM_VERBOSITY=UVM_HIGH \
	     -top hdl_top -top hvl_top

p2_batch:
	qrun -64 -coverage -classdebug -uvmcontrol=all -msgmode both -suppress 8887 -l run.log \
	     -f files.f +acc -sv_seed random \
	     +UVM_TESTNAME=$(TESTNAME) \
	     -top hdl_top -top hvl_top \
	     -do "run -a; coverage save decode_in_coverage.ucdb; quit -f;"

clean:
	rm -rf work qrun.out transcript *.log *.wlf qwave.db *.ucdb run.log certe_dump.xml design.bin
