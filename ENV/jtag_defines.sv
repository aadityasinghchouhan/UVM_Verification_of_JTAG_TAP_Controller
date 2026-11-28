`ifndef JTAG_DEFINES
`define JTAG_DEFINES

//-----------------------------------------------------------------------------
// Common definitions used by the whole testbench
//-----------------------------------------------------------------------------

// TAP states (same encoding as the RTL)
typedef enum bit [3:0] {
    TEST_LOGIC_RESET = 4'd0,
    RUN_TEST_IDLE    = 4'd1,
    SELECT_DR_SCAN   = 4'd2,
    CAPTURE_DR       = 4'd3,
    SHIFT_DR         = 4'd4,
    EXIT1_DR         = 4'd5,
    PAUSE_DR         = 4'd6,
    EXIT2_DR         = 4'd7,
    UPDATE_DR        = 4'd8,
    SELECT_IR_SCAN   = 4'd9,
    CAPTURE_IR       = 4'd10,
    SHIFT_IR         = 4'd11,
    EXIT1_IR         = 4'd12,
    PAUSE_IR         = 4'd13,
    EXIT2_IR         = 4'd14,
    UPDATE_IR        = 4'd15
} tap_state_e;

// Instructions
parameter bit [3:0]  IDCODE_OP = 4'b0001;
parameter bit [3:0]  BYPASS_OP = 4'b1111;

// Expected IDCODE value (must match the RTL parameter)
parameter bit [31:0] EXPECTED_IDCODE = 32'h1CAFE157;

// Instruction register capture value (LSBs = "01")
parameter bit [3:0]  IR_CAPTURE_VALUE = 4'b0001;

//-----------------------------------------------------------------------------
// TAP state diagram written from the IEEE 1149.1 specification.
// Used by the sequences (to know where the TAP is) and the scoreboard
// (reference model). It is written separately from the RTL.
//-----------------------------------------------------------------------------
function automatic tap_state_e tap_next_state(tap_state_e cur, bit tms);
    case (cur)
        TEST_LOGIC_RESET : return tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
        RUN_TEST_IDLE    : return tms ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
        SELECT_DR_SCAN   : return tms ? SELECT_IR_SCAN   : CAPTURE_DR;
        CAPTURE_DR       : return tms ? EXIT1_DR         : SHIFT_DR;
        SHIFT_DR         : return tms ? EXIT1_DR         : SHIFT_DR;
        EXIT1_DR         : return tms ? UPDATE_DR        : PAUSE_DR;
        PAUSE_DR         : return tms ? EXIT2_DR         : PAUSE_DR;
        EXIT2_DR         : return tms ? UPDATE_DR        : SHIFT_DR;
        UPDATE_DR        : return tms ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
        SELECT_IR_SCAN   : return tms ? TEST_LOGIC_RESET : CAPTURE_IR;
        CAPTURE_IR       : return tms ? EXIT1_IR         : SHIFT_IR;
        SHIFT_IR         : return tms ? EXIT1_IR         : SHIFT_IR;
        EXIT1_IR         : return tms ? UPDATE_IR        : PAUSE_IR;
        PAUSE_IR         : return tms ? EXIT2_IR         : PAUSE_IR;
        EXIT2_IR         : return tms ? UPDATE_IR        : SHIFT_IR;
        UPDATE_IR        : return tms ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
        default          : return TEST_LOGIC_RESET;
    endcase
endfunction

//-----------------------------------------------------------------------------
// Cover-property hit counters. Incremented by the cover properties in
// TOP/jtag_sva.sv and printed by jtag_cov in the report phase.
//-----------------------------------------------------------------------------
int unsigned c_trst_reset, c_tms_5_reset, c_pause_dr_resume, c_pause_ir_resume;
int unsigned c_ir_capture, c_ir_update, c_idcode_capture, c_bypass_capture;
int unsigned c_tdo_enable, c_reset_in_shift, c_ir_shift, c_dr_select;

`endif
