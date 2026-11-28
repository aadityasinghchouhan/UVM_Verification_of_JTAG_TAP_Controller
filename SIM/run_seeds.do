#-----------------------------------------------------------------------------
# run_seeds.do - random test (TC6) with 10 different random seeds
#
# Shows that the random test passes for many different random stimulus
# patterns, not only for one lucky seed.
#
# Run it from the SIM folder:
#   Command line : vsim -c -do run_seeds.do
#   Questa GUI   : do run_seeds.do
#
# Output (in the RESULTS folder):
#   RESULTS/seeds/seed_<N>.log
#   RESULTS/seeds/seeds_summary.txt
#-----------------------------------------------------------------------------

onbreak {resume}

set out_dir ../RESULTS/seeds
file mkdir $out_dir

set seeds {1 7 42 99 123 555 2026 3141 8080 9999}

# fresh work library
if {[file exists work]} { vdel -lib work -all }
vlib work
vlog -sv +cover=bcesft ../RTL/jtag_tap.sv -l $out_dir/compile_rtl.log
vlog -sv ../TEST/jtag_pkg.sv ../TOP/jtag_sva.sv ../TOP/jtag_top.sv +incdir+../ENV +incdir+../TEST +incdir+../TOP -l $out_dir/compile_tb.log

foreach s $seeds {
    transcript file $out_dir/seed_${s}.log
    vsim -vopt -onfinish stop -sv_seed $s jtag_top +UVM_TESTNAME=jtag_random_tc6
    run -all
    quit -sim
}
transcript file transcript

# summary (printed and saved to a file)
set fails 0
set lines {}
lappend lines "=============== RANDOM TEST (TC6) - MULTI-SEED SUMMARY ==============="
lappend lines [format "  %-8s  %-12s  %-10s  %-10s  %s" "SEED" "RESULT" "UVM_ERROR" "CYCLES" "FUNCTIONAL COVERAGE"]
foreach s $seeds {
    set res "RESULT NOT FOUND"
    set err "-"
    set cyc "-"
    set cov "-"
    if {[file exists $out_dir/seed_${s}.log]} {
        set f [open $out_dir/seed_${s}.log r]
        set txt [read $f]
        close $f
        regexp {RESULT\s*:\s*(TEST \w+)} $txt -> res
        regexp {UVM_ERROR\s*:\s*([0-9]+)} $txt -> err
        regexp {TCK cycles checked\s*:\s*([0-9]+)} $txt -> cyc
        regexp {Total Coverage\s*:\s*([0-9.]+)} $txt -> cov
    }
    if {$res ne "TEST PASSED" || $err ne "0"} { incr fails }
    lappend lines [format "  %-8s  %-12s  %-10s  %-10s  %s %%" $s $res $err $cyc $cov]
}
lappend lines "======================================================================"
if {$fails == 0} {
    lappend lines "  OVERALL : ALL [llength $seeds] SEEDS PASSED"
} else {
    lappend lines "  OVERALL : $fails SEED(S) FAILED - see RESULTS/seeds"
}
lappend lines "======================================================================"

set f [open $out_dir/seeds_summary.txt w]
foreach l $lines { puts $f $l }
close $f
puts ""
foreach l $lines { puts $l }
puts "Saved to RESULTS/seeds/seeds_summary.txt"

if {[batch_mode]} { quit -f }
