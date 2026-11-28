#-----------------------------------------------------------------------------
# run_cov.do - merged coverage report (functional + code + assertions)
#
# Runs TC1 to TC7 with coverage collection, merges the results and writes
# text and HTML reports. Code coverage (statement, branch, condition,
# expression, FSM, toggle) is collected on the DESIGN only (RTL/jtag_tap.sv),
# not on the testbench.
# Needs a QuestaSim coverage license.
#
# Run it from the SIM folder:
#   Command line : vsim -c -do run_cov.do
#   Questa GUI   : do run_cov.do
#
# Output (in the RESULTS folder):
#   RESULTS/coverage/coverage_summary.txt   short summary
#   RESULTS/coverage/coverage_report.txt    full details
#   RESULTS/coverage/covhtmlreport/         HTML report (open index.html)
#   RESULTS/coverage/tc<N>_cov.log          simulation logs
#-----------------------------------------------------------------------------

onbreak {resume}

set out_dir ../RESULTS/coverage
file mkdir $out_dir

# fresh work library
if {[file exists work]} { vdel -lib work -all }
vlib work
# code coverage only on the design
vlog -sv +cover=bcesft ../RTL/jtag_tap.sv -l $out_dir/compile_rtl.log
vlog -sv ../TEST/jtag_pkg.sv ../TOP/jtag_sva.sv ../TOP/jtag_top.sv +incdir+../ENV +incdir+../TEST +incdir+../TOP -l $out_dir/compile_tb.log

set tests {jtag_reset_tc1 jtag_fsm_tc2 jtag_ir_tc3 jtag_idcode_tc4 jtag_bypass_tc5 jtag_random_tc6 jtag_corner_tc7}

set ucdbs {}
set n 1
foreach t $tests {
    transcript file $out_dir/tc${n}_cov.log
    vsim -coverage -vopt -onfinish stop jtag_top +UVM_TESTNAME=$t
    coverage save -onexit tc${n}cov.ucdb
    run -all
    quit -sim
    lappend ucdbs tc${n}cov.ucdb
    incr n
}
transcript file transcript

# merge and report
eval vcover merge mergecov.ucdb $ucdbs
vcover report mergecov.ucdb -file $out_dir/coverage_summary.txt
vcover report -details mergecov.ucdb -file $out_dir/coverage_report.txt
if {[file exists covhtmlreport]} { file delete -force covhtmlreport }
vcover report -details -html mergecov.ucdb
if {[file exists $out_dir/covhtmlreport]} { file delete -force $out_dir/covhtmlreport }
file copy -force covhtmlreport $out_dir/covhtmlreport

puts ""
puts "Coverage reports saved to RESULTS/coverage:"
puts "  coverage_summary.txt, coverage_report.txt, covhtmlreport/index.html"

if {[batch_mode]} { quit -f }
