`ifndef JTAG_TRANS
`define JTAG_TRANS

//-----------------------------------------------------------------------------
// One transaction = one TCK cycle
//   Driver uses : trst_n, tms, tdi
//   Monitor adds: tdo, tdo_en, tap_state, ir_reg (what the DUT shows)
//-----------------------------------------------------------------------------
class jtag_trans extends uvm_sequence_item;

    //stimulus
    rand bit trst_n;
    rand bit tms;
    rand bit tdi;

    //observed DUT outputs (filled by monitor)
    bit         tdo;
    bit         tdo_en;
    tap_state_e tap_state;
    bit [3:0]   ir_reg;

    //TRST_N is asserted only rarely during random traffic
    constraint RESET_C { trst_n dist {0 := 1, 1 := 99}; }

    //factory registration with field macros
    `uvm_object_utils_begin(jtag_trans)
        `uvm_field_int(trst_n, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(tms, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(tdi, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(tdo, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(tdo_en, UVM_ALL_ON | UVM_BIN)
        `uvm_field_enum(tap_state_e, tap_state, UVM_ALL_ON)
        `uvm_field_int(ir_reg, UVM_ALL_ON | UVM_BIN)
    `uvm_object_utils_end

    //Function new - constructor
    function new(string name = "jtag_trans");
        super.new(name);
    endfunction

endclass : jtag_trans

`endif
