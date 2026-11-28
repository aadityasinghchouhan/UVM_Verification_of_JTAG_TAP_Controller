#-----------------------------------------------------------------------------
# run_all.do - compile and run every JTAG TAP test (regression)
#
# Run it from the SIM folder:
#   Command line : vsim -c -do run_all.do
#   Questa GUI   : File > Change Directory... (select the SIM folder)
#                  then type in the Transcript window:  do run_all.do
#
# Output (in the RESULTS folder):
#   RESULTS/regression/<test name>.log      one log per test
#   RESULTS/regression/regression_summary.txt
#-----------------------------------------------------------------------------

onbreak {resume}

set out_dir ../RESULTS/regression
file mkdir $out_dir

# fresh work library
if {[file exists work]} { vdel -lib work -all }
vlib work

# compile: design (with code coverage enabled) + UVM testbench + assertions
vlog -sv +cover=bcesft ../RTL/jtag_tap.sv -l $out_dir/compile_rtl.log
vlog -sv ../TEST/jtag_pkg.sv ../TOP/jtag_sva.sv ../TOP/jtag_top.sv +incdir+../ENV +incdir+../TEST +incdir+../TOP -l $out_dir/compile_tb.log

set tests {jtag_base_test jtag_reset_tc1 jtag_fsm_tc2 jtag_ir_tc3 jtag_idcode_tc4 jtag_bypass_tc5 jtag_random_tc6 jtag_corner_tc7 jtag_regression_tc8}

# run every test, one log file per test
foreach t $tests {
    transcript file $out_dir/${t}.log
    vsim -vopt -onfinish stop jtag_top +UVM_TESTNAME=$t
    run -all
    quit -sim
}
transcript file transcript

# summary (printed and saved to a file)
set fails 0
set lines {}
lappend lines "======================== JTAG TAP REGRESSION SUMMARY ========================"
lappend lines [format "  %-22s  %-12s  %-14s  %s" "TEST" "RESULT" "UVM_ERROR" "FUNCTIONAL COVERAGE"]
foreach t $tests {
    set res "RESULT NOT FOUND"
    set cov "-"
    set err "-"
    if {[file exists $out_dir/${t}.log]} {
        set f [open $out_dir/${t}.log r]
        set txt [read $f]
        close $f
        regexp {RESULT\s*:\s*(TEST \w+)} $txt -> res
        regexp {Total Coverage\s*:\s*([0-9.]+)} $txt -> cov
        regexp {UVM_ERROR\s*:\s*([0-9]+)} $txt -> err
    }
    if {$res ne "TEST PASSED" || $err ne "0"} { incr fails }
    lappend lines [format "  %-22s  %-12s  %-14s  %s %%" $t $res $err $cov]
}
lappend lines "============================================================================="
if {$fails == 0} {
    lappend lines "  OVERALL : ALL [llength $tests] TESTS PASSED"
} else {
    lappend lines "  OVERALL : $fails TEST(S) FAILED - see the logs in RESULTS/regression"
}
lappend lines "============================================================================="

set f [open $out_dir/regression_summary.txt w]
foreach l $lines { puts $f $l }
close $f
puts ""
foreach l $lines { puts $l }
puts "Saved to RESULTS/regression/regression_summary.txt"

# leave QuestaSim only when started from the command line (vsim -c)
if {[batch_mode]} { quit -f }
