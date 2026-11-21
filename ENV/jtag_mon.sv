`ifndef JTAG_MON
`define JTAG_MON

class jtag_mon extends uvm_monitor;

    //Factory registration
    `uvm_component_utils(jtag_mon)

    //Virtual interface - monitor modport
    virtual jtag_if.MON_MP vif;

    //Analysis port -> sends every sampled TCK cycle to scoreboard and coverage
    uvm_analysis_port #(jtag_trans) analysis_port;

    jtag_trans trans_h;

    //Function new - constructor
    function new(string name = "jtag_mon", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        forever
        begin
            sample_from_dut();
            analysis_port.write(trans_h);
        end
    endtask

    //Samples pins just before the rising edge of TCK
    task sample_from_dut();
        @(vif.mon_cb);
        //DUT outputs must never be X/Z once reset has been applied
        if(vif.mon_cb.trst_n === 1'b1 &&
           $isunknown({vif.mon_cb.tdo, vif.mon_cb.tdo_en, vif.mon_cb.tap_state, vif.mon_cb.ir_reg}))
            `uvm_error("JTAG_MON", "Unknown (X/Z) value on a DUT output")

        trans_h = jtag_trans :: type_id :: create("trans_h");
        trans_h.trst_n    = vif.mon_cb.trst_n;
        trans_h.tms       = vif.mon_cb.tms;
        trans_h.tdi       = vif.mon_cb.tdi;
        trans_h.tdo       = vif.mon_cb.tdo;
        trans_h.tdo_en    = vif.mon_cb.tdo_en;
        trans_h.tap_state = tap_state_e'(vif.mon_cb.tap_state);
        trans_h.ir_reg    = vif.mon_cb.ir_reg;
        `uvm_info("JTAG_MON", $sformatf("Sampled : state=%s ir=%b tms=%0b tdi=%0b tdo=%0b tdo_en=%0b",
                  trans_h.tap_state.name(), trans_h.ir_reg, trans_h.tms, trans_h.tdi, trans_h.tdo, trans_h.tdo_en), UVM_HIGH)
    endtask

endclass : jtag_mon

`endif
