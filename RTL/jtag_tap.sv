//-----------------------------------------------------------------------------
// JTAG (IEEE 1149.1) TAP Controller
//
//  - 16-state TAP FSM controlled by TMS, active-low asynchronous TRST_N
//  - 4-bit Instruction Register (IR) with instruction decoder
//  - Data registers : BYPASS (1-bit) and IDCODE (32-bit)
//  - Rising  edge of TCK : FSM state change, Capture and Shift
//  - Falling edge of TCK : Update-IR, TDO and TDO enable change
//
//  Instructions:
//      IDCODE = 4'b0001  -> selects 32-bit IDCODE register (default after reset)
//      BYPASS = 4'b1111  -> selects 1-bit BYPASS register
//      Any other opcode  -> treated as BYPASS
//-----------------------------------------------------------------------------
module jtag_tap #(parameter logic [31:0] IDCODE_VALUE = 32'h1CAFE157) (
    input  logic       tck,
    input  logic       trst_n,
    input  logic       tms,
    input  logic       tdi,
    output logic       tdo,
    output logic       tdo_en,           // 1 only while shifting (Shift-IR / Shift-DR)

    // observation ports (current FSM state and active instruction)
    output logic [3:0] tap_state,
    output logic [3:0] ir_reg,

    // control signals decoded from the FSM state
    output logic       test_logic_reset,
    output logic       run_test_idle,
    output logic       capture_dr,
    output logic       shift_dr,
    output logic       update_dr,
    output logic       capture_ir,
    output logic       shift_ir,
    output logic       update_ir
);

    //---------------------------------------------------------------
    // TAP state encoding
    //---------------------------------------------------------------
    localparam logic [3:0] TEST_LOGIC_RESET = 4'd0,
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
                           UPDATE_IR        = 4'd15;

    // instruction opcodes
    localparam logic [3:0] IDCODE = 4'b0001,
                           BYPASS = 4'b1111;

    //---------------------------------------------------------------
    // internal registers
    //---------------------------------------------------------------
    logic [3:0]  state, next_state;
    logic [3:0]  ir_shift_reg;     // IR shift stage
    logic [31:0] idcode_reg;       // IDCODE shift register
    logic        bypass_reg;       // BYPASS register

    //---------------------------------------------------------------
    // Next-state logic (TAP state diagram)
    //---------------------------------------------------------------
    always_comb begin
        case (state)
            TEST_LOGIC_RESET : next_state = tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE    : next_state = tms ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_DR_SCAN   : next_state = tms ? SELECT_IR_SCAN   : CAPTURE_DR;
            CAPTURE_DR       : next_state = tms ? EXIT1_DR         : SHIFT_DR;
            SHIFT_DR         : next_state = tms ? EXIT1_DR         : SHIFT_DR;
            EXIT1_DR         : next_state = tms ? UPDATE_DR        : PAUSE_DR;
            PAUSE_DR         : next_state = tms ? EXIT2_DR         : PAUSE_DR;
            EXIT2_DR         : next_state = tms ? UPDATE_DR        : SHIFT_DR;
            UPDATE_DR        : next_state = tms ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            SELECT_IR_SCAN   : next_state = tms ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR       : next_state = tms ? EXIT1_IR         : SHIFT_IR;
            SHIFT_IR         : next_state = tms ? EXIT1_IR         : SHIFT_IR;
            EXIT1_IR         : next_state = tms ? UPDATE_IR        : PAUSE_IR;
            PAUSE_IR         : next_state = tms ? EXIT2_IR         : PAUSE_IR;
            EXIT2_IR         : next_state = tms ? UPDATE_IR        : SHIFT_IR;
            UPDATE_IR        : next_state = tms ? SELECT_DR_SCAN   : RUN_TEST_IDLE;
            default          : next_state = TEST_LOGIC_RESET;
        endcase
    end

    //---------------------------------------------------------------
    // Rising edge : state register, Capture and Shift operations
    //---------------------------------------------------------------
    always_ff @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            state        <= TEST_LOGIC_RESET;
            ir_shift_reg <= 4'b0001;
            idcode_reg   <= 32'd0;
            bypass_reg   <= 1'b0;
        end
        else begin
            state <= next_state;
            case (state)
                CAPTURE_IR : ir_shift_reg <= 4'b0001;                    // LSBs must be "01"
                SHIFT_IR   : ir_shift_reg <= {tdi, ir_shift_reg[3:1]};   // shift right, LSB first
                CAPTURE_DR : begin
                    if (ir_reg == IDCODE) idcode_reg <= IDCODE_VALUE;
                    else                  bypass_reg <= 1'b0;            // BYPASS captures 0
                end
                SHIFT_DR   : begin
                    if (ir_reg == IDCODE) idcode_reg <= {tdi, idcode_reg[31:1]};
                    else                  bypass_reg <= tdi;
                end
                default    : ;
            endcase
        end
    end

    //---------------------------------------------------------------
    // Falling edge : Update-IR, TDO and TDO enable
    //---------------------------------------------------------------
    always_ff @(negedge tck or negedge trst_n) begin
        if (!trst_n) begin
            ir_reg <= IDCODE;              // IDCODE is the default instruction
            tdo    <= 1'b0;
            tdo_en <= 1'b0;
        end
        else begin
            // instruction register
            if (state == TEST_LOGIC_RESET) ir_reg <= IDCODE;
            else if (state == UPDATE_IR)   ir_reg <= ir_shift_reg;

            // TDO is driven only in the Shift states, and only changes on the falling edge
            tdo_en <= (state == SHIFT_IR) || (state == SHIFT_DR);

            if (state == SHIFT_IR)
                tdo <= ir_shift_reg[0];
            else if (state == SHIFT_DR)
                tdo <= (ir_reg == IDCODE) ? idcode_reg[0] : bypass_reg;
            else
                tdo <= 1'b0;
        end
    end

    //---------------------------------------------------------------
    // Outputs
    //---------------------------------------------------------------
    assign tap_state        = state;
    assign test_logic_reset = (state == TEST_LOGIC_RESET);
    assign run_test_idle    = (state == RUN_TEST_IDLE);
    assign capture_dr       = (state == CAPTURE_DR);
    assign shift_dr         = (state == SHIFT_DR);
    assign update_dr        = (state == UPDATE_DR);
    assign capture_ir       = (state == CAPTURE_IR);
    assign shift_ir         = (state == SHIFT_IR);
    assign update_ir        = (state == UPDATE_IR);

endmodule : jtag_tap
