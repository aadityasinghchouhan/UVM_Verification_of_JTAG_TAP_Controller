`ifndef JTAG_BYPASS_TC5
`define JTAG_BYPASS_TC5

class jtag_bypass_tc5 extends jtag_base_test;

    `uvm_component_utils(jtag_bypass_tc5)

    jtag_bypass_seqs_tc5 seqs_h_tc;

    function new(string name = "jtag_bypass_tc5", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqs_h_tc = jtag_bypass_seqs_tc5 :: type_id :: create("seqs_h_tc");
        seqs_h_tc.start(env_h.agent_h.seqr_h);
        #50;
        phase.drop_objection(this);
    endtask

endclass : jtag_bypass_tc5

`endif
