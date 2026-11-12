// Lines to add to project_benches/lc3/sim/files.f (relative to the sim directory).
// Order matters: lc3_prediction_pkg and both interface packages must compile before
// control_env_pkg, and control_env_pkg before lc3_env_pkg / lc3_test_pkg.
// (lc3_prediction_pkg is already in files.f from P2 - do not list it twice.)
// control_in_driver_bfm is compiled even though the LC3 bench never instantiates it:
// control_in_configuration declares a `virtual control_in_driver_bfm` handle, so the
// type must exist (same as decode_in_driver_bfm at LC3 level).
+incdir+../../../verification_ip/interface_packages/control_in_pkg
../../../verification_ip/interface_packages/control_in_pkg/control_in_pkg.sv
../../../verification_ip/interface_packages/control_in_pkg/src/control_in_if.sv
../../../verification_ip/interface_packages/control_in_pkg/src/control_in_driver_bfm.sv
../../../verification_ip/interface_packages/control_in_pkg/src/control_in_monitor_bfm.sv
+incdir+../../../verification_ip/interface_packages/control_out_pkg
../../../verification_ip/interface_packages/control_out_pkg/control_out_pkg.sv
../../../verification_ip/interface_packages/control_out_pkg/src/control_out_if.sv
../../../verification_ip/interface_packages/control_out_pkg/src/control_out_monitor_bfm.sv
+incdir+../../../verification_ip/environment_packages/control_env_pkg
../../../verification_ip/environment_packages/control_env_pkg/control_env_pkg.sv
