`ifndef JTAG_ENV
`define JTAG_ENV

class jtag_env extends uvm_env;

    //Factory registration
    `uvm_component_utils(jtag_env)

    //Environment components
    jtag_agent agent_h;
    jtag_sb    sb_h;
    jtag_cov   cov_h;

    //Function new - constructor
    function new(string name = "jtag_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent_h = jtag_agent :: type_id :: create("agent_h", this);
        sb_h    = jtag_sb    :: type_id :: create("sb_h", this);
        cov_h   = jtag_cov   :: type_id :: create("cov_h", this);
    endfunction

    //Monitor -> Scoreboard (analysis fifo) and Monitor -> Coverage (subscriber)
    function void connect_phase(uvm_phase phase);
        agent_h.mon_h.analysis_port.connect(sb_h.mon_analysis_fifo.analysis_export);
        agent_h.mon_h.analysis_port.connect(cov_h.analysis_export);
    endfunction

endclass : jtag_env

`endif
