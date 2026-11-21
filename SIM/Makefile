#Makefile - JTAG TAP Controller UVM (QuestaSim)
RTL=../RTL/jtag_tap.sv
RTLModule=jtag_tap
PKG=../TEST/jtag_pkg.sv
SVA=../TOP/jtag_sva.sv
TB=../TOP/jtag_top.sv
TBModule=jtag_top
INC=+incdir+../ENV +incdir+../TEST +incdir+../TOP


help:
	@echo ===========================================================================================
	@echo " lib          ==>  Make work directory"
	@echo " cmp          ==>  Compile RTL + UVM testbench + assertions"
	@echo " sim          ==>  Run base (smoke) test"
	@echo " run_all      ==>  lib + cmp + sim"
	@echo " run_tc1      ==>  TESTCASE-1 -> RESET_TEST"
	@echo " run_tc2      ==>  TESTCASE-2 -> FSM_STATE_TRANSITION_TEST"
	@echo " run_tc3      ==>  TESTCASE-3 -> INSTRUCTION_REGISTER_TEST"
	@echo " run_tc4      ==>  TESTCASE-4 -> IDCODE_TEST"
	@echo " run_tc5      ==>  TESTCASE-5 -> BYPASS_TEST"
	@echo " run_tc6      ==>  TESTCASE-6 -> RANDOM_TEST"
	@echo " run_tc7      ==>  TESTCASE-7 -> CORNER_CASE_TEST"
	@echo " run_tc8      ==>  TESTCASE-8 -> REGRESSION_TEST (TC1-TC7 in one run)"
	@echo " regress      ==>  Compile and run TC1 to TC8 one after another"
	@echo " run_merge    ==>  Run TC1-TC7 with coverage, merge and make HTML report"
	@echo " gui          ==>  Open GUI with waveform (TEST=<testname>)"
	@echo " clean        ==>  Delete work library, logs and coverage files"
	@echo ===========================================================================================

lib :
	vlib work

cmp :
	vlog -sv +cover=bcesf $(RTL) $(PKG) $(SVA) $(TB) $(INC) -l compile.log

sim :
	vsim -vopt $(TBModule) -c -do "run -all; exit" -l base_test.log

tc1 :
	vsim -vopt $(TBModule) -c -do "run -all; exit" +UVM_TESTNAME=jtag_reset_tc1 -l tc1_reset.log

tc2 :
	vsim -vopt $(TBModule) -c -do "run -all; exit" +UVM_TESTNAME=jtag_fsm_tc2 -l tc2_fsm.log

tc3 :
	vsim -vopt $(TBModule) -c -do "run -all; exit" +UVM_TESTNAME=jtag_ir_tc3 -l tc3_ir.log

tc4 :
	vsim -vopt $(TBModule) -c -do "run -all; exit" +UVM_TESTNAME=jtag_idcode_tc4 -l tc4_idcode.log

tc5 :
	vsim -vopt $(TBModule) -c -do "run -all; exit" +UVM_TESTNAME=jtag_bypass_tc5 -l tc5_bypass.log

tc6 :
	vsim -vopt $(TBModule) -c -do "run -all; exit" +UVM_TESTNAME=jtag_random_tc6 -sv_seed random -l tc6_random.log

tc7 :
	vsim -vopt $(TBModule) -c -do "run -all; exit" +UVM_TESTNAME=jtag_corner_tc7 -l tc7_corner.log

tc8 :
	vsim -vopt $(TBModule) -c -do "run -all; exit" +UVM_TESTNAME=jtag_regression_tc8 -l tc8_regression.log

tc1_cov :
	vsim -coverage -vopt $(TBModule) -c -do "coverage save -onexit tc1cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_reset_tc1 -l tc1_reset.log

tc2_cov :
	vsim -coverage -vopt $(TBModule) -c -do "coverage save -onexit tc2cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_fsm_tc2 -l tc2_fsm.log

tc3_cov :
	vsim -coverage -vopt $(TBModule) -c -do "coverage save -onexit tc3cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_ir_tc3 -l tc3_ir.log

tc4_cov :
	vsim -coverage -vopt $(TBModule) -c -do "coverage save -onexit tc4cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_idcode_tc4 -l tc4_idcode.log

tc5_cov :
	vsim -coverage -vopt $(TBModule) -c -do "coverage save -onexit tc5cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_bypass_tc5 -l tc5_bypass.log

tc6_cov :
	vsim -coverage -vopt $(TBModule) -c -do "coverage save -onexit tc6cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_random_tc6 -l tc6_random.log

tc7_cov :
	vsim -coverage -vopt $(TBModule) -c -do "coverage save -onexit tc7cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_corner_tc7 -l tc7_corner.log

merge_cov :
	vcover merge mergecov.ucdb tc1cov.ucdb tc2cov.ucdb tc3cov.ucdb tc4cov.ucdb tc5cov.ucdb tc6cov.ucdb tc7cov.ucdb

merge_report :
	vcover report -details -html mergecov.ucdb
	vcover report -details mergecov.ucdb -file coverage_report.txt

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

regress : lib cmp tc1 tc2 tc3 tc4 tc5 tc6 tc7 tc8

run_merge : lib cmp tc1_cov tc2_cov tc3_cov tc4_cov tc5_cov tc6_cov tc7_cov merge_cov merge_report
