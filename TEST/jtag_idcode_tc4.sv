`ifndef JTAG_IDCODE_TC4
`define JTAG_IDCODE_TC4

class jtag_idcode_tc4 extends jtag_base_test;

    `uvm_component_utils(jtag_idcode_tc4)

    jtag_idcode_seqs_tc4 seqs_h_tc;

    function new(string name = "jtag_idcode_tc4", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqs_h_tc = jtag_idcode_seqs_tc4 :: type_id :: create("seqs_h_tc");
        seqs_h_tc.start(env_h.agent_h.seqr_h);
        #50;
        phase.drop_objection(this);
    endtask

endclass : jtag_idcode_tc4

`endif
