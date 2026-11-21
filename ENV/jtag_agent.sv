`ifndef JTAG_AGENT
`define JTAG_AGENT

class jtag_agent extends uvm_agent;

    //Factory registration
    `uvm_component_utils(jtag_agent)

    //Virtual interface -> received from jtag_top through config_db
    virtual jtag_if vif;

    //Configuration object
    jtag_config config_data;

    //Agent components
    jtag_seqr seqr_h;
    jtag_drv  drv_h;
    jtag_mon  mon_h;

    //Function new - constructor
    function new(string name = "jtag_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(virtual jtag_if) :: get(this, "", "vif", vif))
            `uvm_fatal("JTAG_AGENT", "Can't get vif... Have you set it ??")

        if(!uvm_config_db #(jtag_config) :: get(this, "", "jtag_config", config_data))
            `uvm_fatal("JTAG_AGENT", "Can't get jtag_config... Have you set it ??")

        mon_h = jtag_mon :: type_id :: create("mon_h", this);

        if(config_data.is_active == UVM_ACTIVE)
        begin
            drv_h  = jtag_drv  :: type_id :: create("drv_h", this);
            seqr_h = jtag_seqr :: type_id :: create("seqr_h", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if(config_data.is_active == UVM_ACTIVE)
        begin
            drv_h.seq_item_port.connect(seqr_h.seq_item_export);
            drv_h.vif = vif;
        end
        mon_h.vif = vif;
    endfunction

endclass : jtag_agent

`endif
