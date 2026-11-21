interface jtag_if(input bit tck);

    // driven by the testbench
    logic       trst_n = 1'b1;
    logic       tms = 1'b1;
    logic       tdi = 1'b0;

    // driven by the DUT
    logic       tdo;
    logic       tdo_en;
    logic [3:0] tap_state;
    logic [3:0] ir_reg;
    logic       test_logic_reset, run_test_idle;
    logic       capture_dr, shift_dr, update_dr;
    logic       capture_ir, shift_ir, update_ir;

    // Driver changes TMS/TDI/TRST_N just after the FALLING edge of TCK
    clocking drv_cb @(negedge tck);
        default output #1;
        output trst_n, tms, tdi;
    endclocking

    // Monitor samples everything just before the RISING edge of TCK
    clocking mon_cb @(posedge tck);
        default input #1;
        input trst_n, tms, tdi, tdo, tdo_en, tap_state, ir_reg;
    endclocking

    modport DRV_MP (clocking drv_cb);

    modport MON_MP (clocking mon_cb);

endinterface : jtag_if
