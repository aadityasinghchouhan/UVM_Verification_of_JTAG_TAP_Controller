`ifndef JTAG_FSM_TC2
`define JTAG_FSM_TC2

class jtag_fsm_tc2 extends jtag_base_test;

    `uvm_component_utils(jtag_fsm_tc2)

    jtag_fsm_seqs_tc2 seqs_h_tc;

    function new(string name = "jtag_fsm_tc2", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqs_h_tc = jtag_fsm_seqs_tc2 :: type_id :: create("seqs_h_tc");
        seqs_h_tc.start(env_h.agent_h.seqr_h);
        #50;
        phase.drop_objection(this);
    endtask

endclass : jtag_fsm_tc2

`endif
