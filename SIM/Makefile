#Makefile - JTAG TAP Controller UVM (QuestaSim)
RTL=../RTL/jtag_tap.sv
PKG=../TEST/jtag_pkg.sv
SVA=../TOP/jtag_sva.sv
TB=../TOP/jtag_top.sv
TBModule=jtag_top
INC=+incdir+../ENV +incdir+../TEST +incdir+../TOP
VSIM=vsim -vopt $(TBModule) -c -do "run -all; exit"


help:
	@echo ===========================================================================================
	@echo " ONE-COMMAND SCRIPTS (same as running the .do files directly)"
	@echo " regress      ==>  Compile + run all 9 tests      -> RESULTS/regression  (run_all.do)"
	@echo " coverage     ==>  Merged coverage report         -> RESULTS/coverage    (run_cov.do)"
	@echo " bugs         ==>  Bug injection experiment       -> RESULTS/bug_injection (run_bugs.do)"
	@echo " seeds        ==>  Random test with 10 seeds      -> RESULTS/seeds       (run_seeds.do)"
	@echo " everything   ==>  regress + coverage + bugs + seeds"
	@echo ""
	@echo " SINGLE TESTS"
	@echo " lib / cmp    ==>  Make work library / compile RTL + testbench"
	@echo " sim          ==>  Run base (smoke) test"
	@echo " run_tc1      ==>  TESTCASE-1 -> RESET_TEST"
	@echo " run_tc2      ==>  TESTCASE-2 -> FSM_STATE_TRANSITION_TEST"
	@echo " run_tc3      ==>  TESTCASE-3 -> INSTRUCTION_REGISTER_TEST"
	@echo " run_tc4      ==>  TESTCASE-4 -> IDCODE_TEST"
	@echo " run_tc5      ==>  TESTCASE-5 -> BYPASS_TEST"
	@echo " run_tc6      ==>  TESTCASE-6 -> RANDOM_TEST"
	@echo " run_tc7      ==>  TESTCASE-7 -> CORNER_CASE_TEST"
	@echo " run_tc8      ==>  TESTCASE-8 -> REGRESSION_TEST (TC1-TC7 in one run)"
	@echo " gui          ==>  Open GUI with waveform (make gui TEST=<testname>)"
	@echo " clean        ==>  Delete work library and generated files in SIM"
	@echo ===========================================================================================

regress :
	vsim -c -do run_all.do

coverage :
	vsim -c -do run_cov.do

bugs :
	vsim -c -do run_bugs.do

seeds :
	vsim -c -do run_seeds.do

everything : regress coverage bugs seeds

lib :
	vlib work

cmp :
	vlog -sv +cover=bcesft $(RTL) -l compile_rtl.log
	vlog -sv $(PKG) $(SVA) $(TB) $(INC) -l compile_tb.log

sim :
	$(VSIM) -l base_test.log

tc1 :
	$(VSIM) +UVM_TESTNAME=jtag_reset_tc1 -l tc1_reset.log

tc2 :
	$(VSIM) +UVM_TESTNAME=jtag_fsm_tc2 -l tc2_fsm.log

tc3 :
	$(VSIM) +UVM_TESTNAME=jtag_ir_tc3 -l tc3_ir.log

tc4 :
	$(VSIM) +UVM_TESTNAME=jtag_idcode_tc4 -l tc4_idcode.log

tc5 :
	$(VSIM) +UVM_TESTNAME=jtag_bypass_tc5 -l tc5_bypass.log

tc6 :
	$(VSIM) +UVM_TESTNAME=jtag_random_tc6 -sv_seed random -l tc6_random.log

tc7 :
	$(VSIM) +UVM_TESTNAME=jtag_corner_tc7 -l tc7_corner.log

tc8 :
	$(VSIM) +UVM_TESTNAME=jtag_regression_tc8 -l tc8_regression.log

gui :
	vsim -vopt -voptargs=+acc $(TBModule) -do run.do +UVM_TESTNAME=$(TEST)

clean :
	vdel -all -lib work

run_all : lib cmp sim

run_tc1 : lib cmp tc1

run_tc2 : lib cmp tc2

run_tc3 : lib cmp tc3

run_tc4 : lib cmp tc4

run_tc5 : lib cmp tc5

run_tc6 : lib cmp tc6

run_tc7 : lib cmp tc7

run_tc8 : lib cmp tc8
