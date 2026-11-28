#-----------------------------------------------------------------------------
# run_bugs.do - bug injection experiment
#
# Each file in ../BUGS is a copy of the RTL with ONE deliberate design error.
# For every bug the design is recompiled and the full regression (TC8) is run.
# A good testbench must report every bug (scoreboard errors and/or assertions).
# The real design in ../RTL is never changed. Afterwards 'work' is deleted,
# so run run_all.do (or 'make cmp') again before running single tests.
#
# Run it from the SIM folder:
#   Command line : vsim -c -do run_bugs.do
#   Questa GUI   : do run_bugs.do
#
# Output (in the RESULTS folder):
#   RESULTS/bug_injection/bug<N>.log
#   RESULTS/bug_injection/bug_summary.txt
#-----------------------------------------------------------------------------

onbreak {resume}

set out_dir ../RESULTS/bug_injection
file mkdir $out_dir

set bugs {
    {1 "IDCODE capture value wrong (bit 8 flipped)"}
    {2 "Pause-DR + TMS=1 goes to Update-DR, not Exit2-DR"}
    {3 "TDO enable decoded from next state (early)"}
    {4 "TMS reset does not restore IDCODE instruction"}
    {5 "BYPASS register captures 1 instead of 0"}
    {6 "IR shifts in the wrong direction"}
    {7 "Unused opcodes select IDCODE instead of BYPASS"}
}

foreach b $bugs {
    set n    [lindex $b 0]
    set desc [lindex $b 1]

    # fresh work library for this bug
    if {[file exists work]} { vdel -lib work -all }
    vlib work

    transcript file $out_dir/bug${n}.log
    puts "BUG $n : $desc"
    vlog -sv ../BUGS/jtag_tap_bug${n}.sv
    vlog -sv ../TEST/jtag_pkg.sv ../TOP/jtag_sva.sv ../TOP/jtag_top.sv +incdir+../ENV +incdir+../TEST +incdir+../TOP
    vsim -vopt -onfinish stop jtag_top +UVM_TESTNAME=jtag_regression_tc8 +UVM_MAX_QUIT_COUNT=200,NO
    run -all
    quit -sim
}
transcript file transcript
# the 'work' library now holds a buggy design: remove it so nobody runs it by mistake
if {[file exists work]} { vdel -lib work -all }

# summary (printed and saved to a file)
set missed 0
set lines {}
lappend lines "================================== BUG INJECTION SUMMARY =================================="
lappend lines [format "  %-4s %-52s %-11s %-10s" "BUG" "DESCRIPTION" "SB ERRORS" "RESULT"]
lappend lines [format "  %-4s %s" "" "ASSERTIONS THAT FIRED"]
lappend lines "-------------------------------------------------------------------------------------------"
foreach b $bugs {
    set n    [lindex $b 0]
    set desc [lindex $b 1]
    set err  0
    set asrt {}
    if {[file exists $out_dir/bug${n}.log]} {
        set f [open $out_dir/bug${n}.log r]
        set txt [read $f]
        close $f
        regexp {UVM_ERROR\s*:\s*([0-9]+)} $txt -> err
        foreach {all name} [regexp -all -inline {(A_[A-Z0-9_]+) :} $txt] {
            if {[lsearch $asrt $name] < 0} { lappend asrt $name }
        }
    }
    if {$err > 0 || [llength $asrt] > 0} {
        set res "DETECTED"
    } else {
        set res "MISSED"
        incr missed
    }
    if {[llength $asrt] == 0} { set asrt_txt "(none - caught by scoreboard only)" } else { set asrt_txt [join $asrt ", "] }
    lappend lines [format "  %-4s %-52s %-11s %-10s" $n $desc $err $res]
    lappend lines [format "  %-4s %s" "" $asrt_txt]
}
lappend lines "==========================================================================================="
lappend lines "  DETECTED : [expr {[llength $bugs] - $missed}] of [llength $bugs] bugs"
lappend lines "  (SB ERRORS = UVM_ERROR count, limited to 200 per run)"
lappend lines "==========================================================================================="

set f [open $out_dir/bug_summary.txt w]
foreach l $lines { puts $f $l }
close $f
puts ""
foreach l $lines { puts $l }
puts "Saved to RESULTS/bug_injection/bug_summary.txt"

if {[batch_mode]} { quit -f }
