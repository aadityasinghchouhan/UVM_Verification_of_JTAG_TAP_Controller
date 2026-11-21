`ifndef JTAG_SEQR
`define JTAG_SEQR

class jtag_seqr extends uvm_sequencer #(jtag_trans);

    //Factory registration
    `uvm_component_utils(jtag_seqr)

    //Function new - constructor
    function new(string name = "jtag_seqr", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : jtag_seqr

`endif
