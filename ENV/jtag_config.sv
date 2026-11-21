`ifndef JTAG_CONFIG
`define JTAG_CONFIG

class jtag_config extends uvm_object;

    //Factory registration
    `uvm_object_utils(jtag_config)

    //Active agent drives the DUT, passive agent only monitors
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    //Function new - constructor
    function new(string name = "jtag_config");
        super.new(name);
    endfunction

endclass : jtag_config

`endif
