// Lines to add to project_benches/lc3/sim/files.f (relative to the sim directory).
// Order matters: lc3_prediction_pkg and both interface packages must compile before
// memaccess_env_pkg, and memaccess_env_pkg before lc3_env_pkg / lc3_test_pkg.
// (lc3_prediction_pkg is already in files.f from P2 - do not list it twice.)
// memaccess_in_driver_bfm is compiled even though the LC3 bench never instantiates
// it: memaccess_in_configuration declares a `virtual memaccess_in_driver_bfm`
// handle, so the type must exist (same as decode_in_driver_bfm and
// control_in_driver_bfm at LC3 level).
+incdir+../../../verification_ip/interface_packages/memaccess_in_pkg
../../../verification_ip/interface_packages/memaccess_in_pkg/memaccess_in_pkg.sv
../../../verification_ip/interface_packages/memaccess_in_pkg/src/memaccess_in_if.sv
../../../verification_ip/interface_packages/memaccess_in_pkg/src/memaccess_in_driver_bfm.sv
../../../verification_ip/interface_packages/memaccess_in_pkg/src/memaccess_in_monitor_bfm.sv
+incdir+../../../verification_ip/interface_packages/memaccess_out_pkg
../../../verification_ip/interface_packages/memaccess_out_pkg/memaccess_out_pkg.sv
../../../verification_ip/interface_packages/memaccess_out_pkg/src/memaccess_out_if.sv
../../../verification_ip/interface_packages/memaccess_out_pkg/src/memaccess_out_monitor_bfm.sv
+incdir+../../../verification_ip/environment_packages/memaccess_env_pkg
../../../verification_ip/environment_packages/memaccess_env_pkg/memaccess_env_pkg.sv
