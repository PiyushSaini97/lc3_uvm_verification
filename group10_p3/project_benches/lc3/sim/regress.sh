#!/bin/sh
# LC3 regression: every test with a fixed seed, then merge with the test plan.
# Run from project_benches/lc3/sim. The first line cleans; the rest add UCDBs.
make lc3_cli   TESTNAME=test_top       SEED=12345
make lc3_batch TESTNAME=test_top       SEED=420    INSTRS=20000
make lc3_batch TESTNAME=lc3_base_test  SEED=543210
make lc3_batch TESTNAME=lc3_alu_test   SEED=69
make lc3_batch TESTNAME=lc3_mem_test   SEED=1111
make lc3_batch TESTNAME=lc3_ctrl_test  SEED=2222
make lc3_batch TESTNAME=lc3_sweep_test SEED=3333
make merge_coverage
make coverage_report
make view_coverage
