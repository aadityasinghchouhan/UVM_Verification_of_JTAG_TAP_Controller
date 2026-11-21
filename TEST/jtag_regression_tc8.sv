`ifndef JTAG_REGRESSION_TC8
`define JTAG_REGRESSION_TC8

class jtag_regression_tc8 extends jtag_base_test;

    `uvm_component_utils(jtag_regression_tc8)

    jtag_regression_seqs_tc8 seqs_h_tc;

    function new(string name = "jtag_regression_tc8", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqs_h_tc = jtag_regression_seqs_tc8 :: type_id :: create("seqs_h_tc");
        seqs_h_tc.start(env_h.agent_h.seqr_h);
        #50;
        phase.drop_objection(this);
    endtask

endclass : jtag_regression_tc8

`endif
