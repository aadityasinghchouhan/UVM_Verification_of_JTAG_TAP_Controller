`ifndef JTAG_CORNER_TC7
`define JTAG_CORNER_TC7

class jtag_corner_tc7 extends jtag_base_test;

    `uvm_component_utils(jtag_corner_tc7)

    jtag_corner_seqs_tc7 seqs_h_tc;

    function new(string name = "jtag_corner_tc7", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqs_h_tc = jtag_corner_seqs_tc7 :: type_id :: create("seqs_h_tc");
        seqs_h_tc.start(env_h.agent_h.seqr_h);
        #50;
        phase.drop_objection(this);
    endtask

endclass : jtag_corner_tc7

`endif
