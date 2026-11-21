# GUI run with waveform
#   vsim -vopt -voptargs=+acc jtag_top -do run.do +UVM_TESTNAME=jtag_corner_tc7
add wave -divider "JTAG PINS"
add wave sim:/jtag_top/tck
add wave sim:/jtag_top/inf/trst_n
add wave sim:/jtag_top/inf/tms
add wave sim:/jtag_top/inf/tdi
add wave sim:/jtag_top/inf/tdo
add wave sim:/jtag_top/inf/tdo_en
add wave -divider "TAP CONTROLLER"
add wave -radix unsigned sim:/jtag_top/JTAG_DUT/state
add wave -radix binary   sim:/jtag_top/JTAG_DUT/ir_reg
add wave -radix binary   sim:/jtag_top/JTAG_DUT/ir_shift_reg
add wave -radix hex      sim:/jtag_top/JTAG_DUT/idcode_reg
add wave sim:/jtag_top/JTAG_DUT/bypass_reg
add wave -divider "CONTROL SIGNALS"
add wave sim:/jtag_top/JTAG_DUT/test_logic_reset
add wave sim:/jtag_top/JTAG_DUT/run_test_idle
add wave sim:/jtag_top/JTAG_DUT/capture_ir
add wave sim:/jtag_top/JTAG_DUT/shift_ir
add wave sim:/jtag_top/JTAG_DUT/update_ir
add wave sim:/jtag_top/JTAG_DUT/capture_dr
add wave sim:/jtag_top/JTAG_DUT/shift_dr
add wave sim:/jtag_top/JTAG_DUT/update_dr
run -all
