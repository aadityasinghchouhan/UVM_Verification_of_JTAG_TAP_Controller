`ifndef JTAG_RESET_TC1
`define JTAG_RESET_TC1

class jtag_reset_tc1 extends jtag_base_test;

    `uvm_component_utils(jtag_reset_tc1)

    jtag_reset_seqs_tc1 seqs_h_tc;

    function new(string name = "jtag_reset_tc1", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqs_h_tc = jtag_reset_seqs_tc1 :: type_id :: create("seqs_h_tc");
        seqs_h_tc.start(env_h.agent_h.seqr_h);
        #50;
        phase.drop_objection(this);
    endtask

endclass : jtag_reset_tc1

`endif
