`ifndef JTAG_REGRESSION_SEQS_TC8
`define JTAG_REGRESSION_SEQS_TC8

//-----------------------------------------------------------------------------
// TC8 : Regression - runs TC1 to TC7 back to back in one simulation
//-----------------------------------------------------------------------------
class jtag_regression_seqs_tc8 extends jtag_base_seqs;

    `uvm_object_utils(jtag_regression_seqs_tc8)

    jtag_reset_seqs_tc1  seqs_tc1;
    jtag_fsm_seqs_tc2    seqs_tc2;
    jtag_ir_seqs_tc3     seqs_tc3;
    jtag_idcode_seqs_tc4 seqs_tc4;
    jtag_bypass_seqs_tc5 seqs_tc5;
    jtag_random_seqs_tc6 seqs_tc6;
    jtag_corner_seqs_tc7 seqs_tc7;

    function new(string name = "jtag_regression_seqs_tc8");
        super.new(name);
    endfunction

    task body();
        seqs_tc1 = jtag_reset_seqs_tc1  :: type_id :: create("seqs_tc1");
        seqs_tc2 = jtag_fsm_seqs_tc2    :: type_id :: create("seqs_tc2");
        seqs_tc3 = jtag_ir_seqs_tc3     :: type_id :: create("seqs_tc3");
        seqs_tc4 = jtag_idcode_seqs_tc4 :: type_id :: create("seqs_tc4");
        seqs_tc5 = jtag_bypass_seqs_tc5 :: type_id :: create("seqs_tc5");
        seqs_tc6 = jtag_random_seqs_tc6 :: type_id :: create("seqs_tc6");
        seqs_tc7 = jtag_corner_seqs_tc7 :: type_id :: create("seqs_tc7");

        seqs_tc1.start(m_sequencer, this);
        seqs_tc2.start(m_sequencer, this);
        seqs_tc3.start(m_sequencer, this);
        seqs_tc4.start(m_sequencer, this);
        seqs_tc5.start(m_sequencer, this);
        seqs_tc6.start(m_sequencer, this);
        seqs_tc7.start(m_sequencer, this);
    endtask

endclass : jtag_regression_seqs_tc8

`endif
