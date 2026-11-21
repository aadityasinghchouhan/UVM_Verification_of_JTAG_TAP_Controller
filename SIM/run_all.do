#-----------------------------------------------------------------------------
# run_all.do - compile and run every JTAG TAP test in QuestaSim
#
# Run it from the SIM folder:
#   Command line : vsim -c -do run_all.do
#   Questa GUI   : File > Change Directory... (select the SIM folder)
#                  then type in the Transcript window:  do run_all.do
#
# Each test writes its own log file (<test name>.log) in the SIM folder.
# A summary table is printed at the end.
#-----------------------------------------------------------------------------

onbreak {resume}

# fresh work library
if {[file exists work]} { vdel -lib work -all }
vlib work

# compile RTL + UVM testbench + assertions (QuestaSim built-in UVM library)
vlog -sv +cover=bcesf ../RTL/jtag_tap.sv ../TEST/jtag_pkg.sv ../TOP/jtag_sva.sv ../TOP/jtag_top.sv +incdir+../ENV +incdir+../TEST +incdir+../TOP -l compile.log

set tests {jtag_base_test jtag_reset_tc1 jtag_fsm_tc2 jtag_ir_tc3 jtag_idcode_tc4 jtag_bypass_tc5 jtag_random_tc6 jtag_corner_tc7 jtag_regression_tc8}

# run every test, one log file per test
foreach t $tests {
    transcript file ${t}.log
    vsim -vopt -onfinish stop jtag_top +UVM_TESTNAME=$t
    run -all
    quit -sim
}
transcript file transcript

# summary
puts ""
puts "======================== JTAG TAP REGRESSION SUMMARY ========================"
foreach t $tests {
    set res "RESULT NOT FOUND"
    set cov "-"
    set err "-"
    if {[file exists ${t}.log]} {
        set f [open ${t}.log r]
        set txt [read $f]
        close $f
        regexp {RESULT\s*:\s*(TEST \w+)} $txt -> res
        regexp {Total Coverage\s*:\s*([0-9.]+)} $txt -> cov
        regexp {UVM_ERROR\s*:\s*([0-9]+)} $txt -> err
    }
    puts [format "  %-22s  %-12s  UVM_ERROR = %-3s  coverage = %s %%" $t $res $err $cov]
}
puts "============================================================================="
puts "Logs: <test name>.log in this folder"

# leave QuestaSim only when started from the command line (vsim -c)
if {[batch_mode]} { quit -f }
