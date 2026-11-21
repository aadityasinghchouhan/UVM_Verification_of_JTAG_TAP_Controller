//-----------------------------------------------------------------------------
// Assertions for the JTAG TAP controller.
// Bound to the DUT from jtag_top (bind), so they can see internal registers.
//-----------------------------------------------------------------------------
module jtag_sva #(parameter logic [31:0] IDCODE_VALUE = 32'h1CAFE157) (
    input logic        tck,
    input logic        trst_n,
    input logic        tms,
    input logic        tdo,
    input logic        tdo_en,
    input logic [3:0]  state,
    input logic [3:0]  ir_reg,
    input logic [3:0]  ir_shift_reg,
    input logic [31:0] idcode_reg,
    input logic        bypass_reg
);

    import jtag_pkg::*;

    //1. TRST_N : TAP is in Test-Logic-Reset, IDCODE selected, TDO disabled
    A_TRST_RESET : assert property (@(posedge tck)
        !trst_n |-> (state == TEST_LOGIC_RESET && ir_reg == IDCODE_OP && !tdo_en))
        else $error("A_TRST_RESET : TRST_N did not reset the TAP");

    //2. TMS high for 5 rising edges always reaches Test-Logic-Reset
    A_TMS_5_RESET : assert property (@(posedge tck) disable iff (!trst_n)
        tms [*5] |=> (state == TEST_LOGIC_RESET))
        else $error("A_TMS_5_RESET : 5 x TMS=1 did not reach Test-Logic-Reset");

    //3. every state change follows the IEEE 1149.1 state diagram
    A_LEGAL_TRANSITION : assert property (@(posedge tck) disable iff (!trst_n)
        1'b1 |=> (state == tap_next_state(tap_state_e'($past(state)), $past(tms))))
        else $error("A_LEGAL_TRANSITION : illegal TAP state transition");

    //4. Capture-IR loads "01" into the two LSBs of the IR
    A_IR_CAPTURE : assert property (@(posedge tck) disable iff (!trst_n)
        (state == CAPTURE_IR) |=> (ir_shift_reg[1:0] == 2'b01))
        else $error("A_IR_CAPTURE : IR capture value is not 01");

    //5. Update-IR loads the shifted instruction (falling edge)
    A_IR_UPDATE : assert property (@(negedge tck) disable iff (!trst_n)
        (state == UPDATE_IR) |=> (ir_reg == $past(ir_shift_reg)))
        else $error("A_IR_UPDATE : instruction not updated in Update-IR");

    //6. the instruction changes only in Update-IR or Test-Logic-Reset
    A_IR_STABLE : assert property (@(negedge tck) disable iff (!trst_n)
        !(state inside {UPDATE_IR, TEST_LOGIC_RESET}) |=> $stable(ir_reg))
        else $error("A_IR_STABLE : instruction changed outside Update-IR");

    //7. Capture-DR with IDCODE loads the 32-bit IDCODE value
    A_IDCODE_CAPTURE : assert property (@(posedge tck) disable iff (!trst_n)
        (state == CAPTURE_DR && ir_reg == IDCODE_OP) |=> (idcode_reg == IDCODE_VALUE))
        else $error("A_IDCODE_CAPTURE : wrong IDCODE captured");

    //8. Capture-DR with any other instruction loads 0 into BYPASS
    A_BYPASS_CAPTURE : assert property (@(posedge tck) disable iff (!trst_n)
        (state == CAPTURE_DR && ir_reg != IDCODE_OP) |=> (bypass_reg == 1'b0))
        else $error("A_BYPASS_CAPTURE : BYPASS did not capture 0");

    //9. TDO is enabled only in Shift-IR / Shift-DR
    A_TDO_ENABLE : assert property (@(posedge tck) disable iff (!trst_n)
        tdo_en == (state inside {SHIFT_IR, SHIFT_DR}))
        else $error("A_TDO_ENABLE : TDO enabled outside a Shift state");

    //10. TDO / TDO enable change only on the falling edge of TCK
    always @(tdo or tdo_en)
        if (trst_n === 1'b1)
            A_TDO_FALLING_EDGE : assert (tck === 1'b0)
                else $error("A_TDO_FALLING_EDGE : TDO changed while TCK was high");

endmodule : jtag_sva
