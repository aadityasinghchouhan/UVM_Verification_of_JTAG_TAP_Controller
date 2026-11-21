import jtag_pkg::*;

module jtag_top();

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter CYCLE = 10;               // TCK period

    bit tck;

    jtag_if inf(tck);

    //Design Instantiation
    jtag_tap #(.IDCODE_VALUE(EXPECTED_IDCODE)) JTAG_DUT (
        .tck              (tck),
        .trst_n           (inf.trst_n),
        .tms              (inf.tms),
        .tdi              (inf.tdi),
        .tdo              (inf.tdo),
        .tdo_en           (inf.tdo_en),
        .tap_state        (inf.tap_state),
        .ir_reg           (inf.ir_reg),
        .test_logic_reset (inf.test_logic_reset),
        .run_test_idle    (inf.run_test_idle),
        .capture_dr       (inf.capture_dr),
        .shift_dr         (inf.shift_dr),
        .update_dr        (inf.update_dr),
        .capture_ir       (inf.capture_ir),
        .shift_ir         (inf.shift_ir),
        .update_ir        (inf.update_ir)
    );

    //Assertions bound to the DUT
    bind jtag_tap jtag_sva #(.IDCODE_VALUE(IDCODE_VALUE)) JTAG_SVA (.*);

    //TCK generation
    initial
    begin
        forever
        begin
            #(CYCLE/2) tck = ~tck;
        end
    end

    //Power-on reset : TRST_N goes 1 -> 0 at 1 ns (a real falling edge)
    initial
    begin
        #1 inf.trst_n = 1'b0;
    end

    initial
    begin
        uvm_config_db #(virtual jtag_if) :: set(null, "*", "vif", inf);

        /*
        Select the test from the command line:
        vsim -vopt jtag_top -c -do "run -all; exit" +UVM_TESTNAME=jtag_reset_tc1
        Without +UVM_TESTNAME the base (smoke) test runs.
        */
        run_test("jtag_base_test");
    end

endmodule : jtag_top
