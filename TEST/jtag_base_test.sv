`ifndef JTAG_BASE_TEST
`define JTAG_BASE_TEST

class jtag_base_test extends uvm_test;

    //Factory registration
    `uvm_component_utils(jtag_base_test)

    //Handles
    jtag_env       env_h;
    jtag_config    config_data;
    jtag_base_seqs seqs_h;

    //Virtual interface
    virtual jtag_if vif;

    //Function new - constructor
    function new(string name = "jtag_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        config_data = jtag_config :: type_id :: create("config_data");
        config_data.is_active = UVM_ACTIVE;
        uvm_config_db #(jtag_config) :: set(this, "*", "jtag_config", config_data);

        if(!uvm_config_db #(virtual jtag_if) :: get(this, "", "vif", vif))
            `uvm_fatal("JTAG_BASE_TEST", "Can't get vif... Have you set it ??")

        env_h = jtag_env :: type_id :: create("env_h", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    //Base test runs the smoke sequence
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seqs_h = jtag_base_seqs :: type_id :: create("seqs_h");
        seqs_h.start(env_h.agent_h.seqr_h);
        #50;                                  // let the last cycles reach the scoreboard
        phase.drop_objection(this);
    endtask

endclass : jtag_base_test

`endif
