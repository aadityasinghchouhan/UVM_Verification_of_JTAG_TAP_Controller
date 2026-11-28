//-----------------------------------------------------------------------------
// Assertions for the JTAG TAP controller.
// Bound to the DUT from jtag_top (bind), so they can see internal registers.
//-----------------------------------------------------------------------------
module jtag_sva #(parameter logic [31:0] IDCODE_VALUE = 32'h1CAFE157) (
    input logic        tck,
    input logic        trst_n,
    input logic        tms,
    input logic        tdi,
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

    //11. TMS reset (Test-Logic-Reset) restores the IDCODE instruction
    //    (added after the bug-injection experiment: bug 4 was missed by assertions)
    A_TLR_IDCODE : assert property (@(negedge tck) disable iff (!trst_n)
        (state == TEST_LOGIC_RESET) |=> (ir_reg == IDCODE_OP))
        else $error("A_TLR_IDCODE : Test-Logic-Reset did not select IDCODE");

    //12. Shift-IR shifts TDI in at the MSB, LSB goes out first
    //    (added after the bug-injection experiment: bug 6 was missed by assertions)
    A_IR_SHIFT : assert property (@(posedge tck) disable iff (!trst_n)
        (state == SHIFT_IR) |=> (ir_shift_reg == {$past(tdi), $past(ir_shift_reg[3:1])}))
        else $error("A_IR_SHIFT : IR did not shift correctly");

    //13. Only the selected data register may change: IDCODE register is untouched
    //    when another instruction is active
    //    (added after the bug-injection experiment: bug 7 was missed by assertions)
    A_DR_SELECT : assert property (@(posedge tck) disable iff (!trst_n)
        (state inside {CAPTURE_DR, SHIFT_DR} && ir_reg != IDCODE_OP) |=> $stable(idcode_reg))
        else $error("A_DR_SELECT : IDCODE register changed while not selected");

    //-------------------------------------------------------------------------
    // Cover properties: prove that the situation each assertion checks really
    // happened in simulation (an assertion that is never triggered proves nothing)
    //-------------------------------------------------------------------------
    // (the hit counters c_* are declared in ENV/jtag_defines.sv and printed by jtag_cov)

    //for A_TRST_RESET
    C_TRST_RESET : cover property (@(posedge tck)
        $fell(trst_n))
        c_trst_reset++;

    //for A_TMS_5_RESET : 5 x TMS=1 starting from a state other than Test-Logic-Reset
    C_TMS_5_RESET : cover property (@(posedge tck) disable iff (!trst_n)
        (state != TEST_LOGIC_RESET && tms) ##1 tms [*4] ##1 (state == TEST_LOGIC_RESET))
        c_tms_5_reset++;

    //for A_LEGAL_TRANSITION : Pause -> Exit2 -> Shift (resume a paused scan)
    C_PAUSE_DR_RESUME : cover property (@(posedge tck) disable iff (!trst_n)
        (state == PAUSE_DR) ##1 (state == EXIT2_DR) ##1 (state == SHIFT_DR))
        c_pause_dr_resume++;

    C_PAUSE_IR_RESUME : cover property (@(posedge tck) disable iff (!trst_n)
        (state == PAUSE_IR) ##1 (state == EXIT2_IR) ##1 (state == SHIFT_IR))
        c_pause_ir_resume++;

    //for A_IR_CAPTURE
    C_IR_CAPTURE : cover property (@(posedge tck) disable iff (!trst_n)
        state == CAPTURE_IR)
        c_ir_capture++;

    //for A_IR_UPDATE and A_IR_STABLE
    C_IR_UPDATE : cover property (@(negedge tck) disable iff (!trst_n)
        state == UPDATE_IR)
        c_ir_update++;

    //for A_IDCODE_CAPTURE
    C_IDCODE_CAPTURE : cover property (@(posedge tck) disable iff (!trst_n)
        state == CAPTURE_DR && ir_reg == IDCODE_OP)
        c_idcode_capture++;

    //for A_BYPASS_CAPTURE
    C_BYPASS_CAPTURE : cover property (@(posedge tck) disable iff (!trst_n)
        state == CAPTURE_DR && ir_reg != IDCODE_OP)
        c_bypass_capture++;

    //for A_TDO_ENABLE and A_TDO_FALLING_EDGE
    C_TDO_ENABLE : cover property (@(posedge tck) disable iff (!trst_n)
        $rose(tdo_en))
        c_tdo_enable++;

    //for A_IR_SHIFT
    C_IR_SHIFT : cover property (@(posedge tck) disable iff (!trst_n)
        state == SHIFT_IR)
        c_ir_shift++;

    //for A_DR_SELECT : shifting data while BYPASS or an unused opcode is active
    C_DR_SELECT : cover property (@(posedge tck) disable iff (!trst_n)
        state == SHIFT_DR && ir_reg != IDCODE_OP)
        c_dr_select++;

    //asynchronous TRST_N in the middle of a scan
    C_RESET_IN_SHIFT : cover property (@(posedge tck)
        (trst_n && state inside {SHIFT_IR, SHIFT_DR}) ##1 !trst_n)
        c_reset_in_shift++;

endmodule : jtag_sva
