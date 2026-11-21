`include "jtag_if.sv"

package jtag_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "jtag_defines.sv"
    `include "jtag_config.sv"

    `include "jtag_trans.sv"

    `include "jtag_base_seqs.sv"
    `include "jtag_reset_seqs_tc1.sv"
    `include "jtag_fsm_seqs_tc2.sv"
    `include "jtag_ir_seqs_tc3.sv"
    `include "jtag_idcode_seqs_tc4.sv"
    `include "jtag_bypass_seqs_tc5.sv"
    `include "jtag_random_seqs_tc6.sv"
    `include "jtag_corner_seqs_tc7.sv"
    `include "jtag_regression_seqs_tc8.sv"

    `include "jtag_seqr.sv"
    `include "jtag_drv.sv"
    `include "jtag_mon.sv"
    `include "jtag_agent.sv"

    `include "jtag_sb.sv"
    `include "jtag_cov.sv"

    `include "jtag_env.sv"

    `include "jtag_base_test.sv"
    `include "jtag_reset_tc1.sv"
    `include "jtag_fsm_tc2.sv"
    `include "jtag_ir_tc3.sv"
    `include "jtag_idcode_tc4.sv"
    `include "jtag_bypass_tc5.sv"
    `include "jtag_random_tc6.sv"
    `include "jtag_corner_tc7.sv"
    `include "jtag_regression_tc8.sv"

endpackage
