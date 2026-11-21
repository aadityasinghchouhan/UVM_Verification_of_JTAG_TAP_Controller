`ifndef JTAG_RANDOM_TC6
`define JTAG_RANDOM_TC6

class jtag_random_tc6 extends jtag_base_test;

    `uvm_component_utils(jtag_random_tc6)

    jtag_random_seqs_tc6 seqs_h_tc;

    function new(string name = "jtag_random_tc6", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqs_h_tc = jtag_random_seqs_tc6 :: type_id :: create("seqs_h_tc");
        seqs_h_tc.start(env_h.agent_h.seqr_h);
        #50;
        phase.drop_objection(this);
    endtask

endclass : jtag_random_tc6

`endif
