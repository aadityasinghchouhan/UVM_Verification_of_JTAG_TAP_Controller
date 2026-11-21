`ifndef JTAG_DRV
`define JTAG_DRV

class jtag_drv extends uvm_driver #(jtag_trans);

    //Factory registration
    `uvm_component_utils(jtag_drv)

    //Virtual interface - driver modport
    virtual jtag_if.DRV_MP vif;

    //Function new - constructor
    function new(string name = "jtag_drv", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        forever
        begin
            //request next transaction from sequencer
            seq_item_port.get_next_item(req);
            //drive one TCK cycle
            drive_to_dut(req);
            //tell sequencer this transaction is done
            seq_item_port.item_done();
        end
    endtask

    //Inputs change after the falling edge; DUT samples them on the next rising edge
    task drive_to_dut(jtag_trans req);
        @(vif.drv_cb);
        vif.drv_cb.trst_n <= req.trst_n;
        vif.drv_cb.tms    <= req.tms;
        vif.drv_cb.tdi    <= req.tdi;
        `uvm_info("JTAG_DRV", $sformatf("Driven : trst_n=%0b tms=%0b tdi=%0b", req.trst_n, req.tms, req.tdi), UVM_HIGH)
    endtask

endclass : jtag_drv

`endif
