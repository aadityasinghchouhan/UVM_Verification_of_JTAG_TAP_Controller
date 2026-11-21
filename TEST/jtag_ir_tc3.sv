`ifndef JTAG_IR_TC3
`define JTAG_IR_TC3

class jtag_ir_tc3 extends jtag_base_test;

    `uvm_component_utils(jtag_ir_tc3)

    jtag_ir_seqs_tc3 seqs_h_tc;

    function new(string name = "jtag_ir_tc3", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqs_h_tc = jtag_ir_seqs_tc3 :: type_id :: create("seqs_h_tc");
        seqs_h_tc.start(env_h.agent_h.seqr_h);
        #50;
        phase.drop_objection(this);
    endtask

endclass : jtag_ir_tc3

`endif
