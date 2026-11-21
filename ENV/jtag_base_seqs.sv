`ifndef JTAG_BASE_SEQS
`define JTAG_BASE_SEQS

//-----------------------------------------------------------------------------
// Base sequence: reusable JTAG operations built from single TCK cycles.
//
//   drive(tms, tdi, trst_n)  : one TCK cycle
//   reset_by_trst()          : TRST_N low, then go to Run-Test/Idle
//   reset_by_tms()           : TMS high for 5 cycles, then go to Run-Test/Idle
//   goto_state(state)        : move the TAP to any state
//   load_ir(opcode)          : IR scan that loads an instruction
//   scan_ir / scan_dr        : IR / DR scan with optional pause in the middle
//
// The sequence keeps its own copy of the TAP state (cur_state) so it always
// knows which TMS values to send.
//-----------------------------------------------------------------------------
class jtag_base_seqs extends uvm_sequence #(jtag_trans);

    //Factory registration
    `uvm_object_utils(jtag_base_seqs)

    jtag_trans  trans_h;
    tap_state_e cur_state = TEST_LOGIC_RESET;

    //Function new - constructor
    function new(string name = "jtag_base_seqs");
        super.new(name);
    endfunction

    //Default body : simple smoke test
    task body();
        reset_by_trst();
        scan_dr(32, 32'h0);              // read IDCODE (default instruction after reset)
        load_ir(BYPASS_OP);
        scan_dr(8, 8'hA5);               // data passes through 1-bit BYPASS register
    endtask

    //------------------------------------------------------------
    // One TCK cycle
    //------------------------------------------------------------
    task drive(bit tms, bit tdi = 0, bit trst_n = 1);
        trans_h = jtag_trans :: type_id :: create("trans_h");
        start_item(trans_h);
        trans_h.trst_n = trst_n;
        trans_h.tms    = tms;
        trans_h.tdi    = tdi;
        finish_item(trans_h);
        cur_state = trst_n ? tap_next_state(cur_state, tms) : TEST_LOGIC_RESET;
    endtask

    //One TCK cycle with random TMS/TDI (TRST_N asserted ~1% of the time)
    task drive_random();
        trans_h = jtag_trans :: type_id :: create("trans_h");
        start_item(trans_h);
        if(!trans_h.randomize())
            `uvm_fatal("JTAG_SEQS", "Randomization failed")
        finish_item(trans_h);
        cur_state = trans_h.trst_n ? tap_next_state(cur_state, trans_h.tms) : TEST_LOGIC_RESET;
    endtask

    task idle(int cycles = 1);
        repeat(cycles) drive(0);
    endtask

    //------------------------------------------------------------
    // Reset
    //------------------------------------------------------------
    task reset_by_trst();
        repeat(2) drive(1, 0, 0);        // TRST_N = 0 for 2 cycles
        drive(0);                        // Test-Logic-Reset -> Run-Test/Idle
    endtask

    task reset_by_tms();
        repeat(5) drive(1);              // 5 x TMS=1 reaches Test-Logic-Reset from any state
        drive(0);                        // -> Run-Test/Idle
    endtask

    //------------------------------------------------------------
    // Go to any state: TMS-reset first, then follow the TMS path
    //------------------------------------------------------------
    task goto_state(tap_state_e target);
        string path;
        if(cur_state == target) return;
        repeat(5) drive(1);              // now in Test-Logic-Reset
        path = tms_path_from_reset(target);
        for(int i = 0; i < path.len(); i++)
            drive(path[i] == "1");
    endtask

    //TMS values to reach each state starting from Test-Logic-Reset
    function string tms_path_from_reset(tap_state_e target);
        case(target)
            TEST_LOGIC_RESET : return "";
            RUN_TEST_IDLE    : return "0";
            SELECT_DR_SCAN   : return "01";
            CAPTURE_DR       : return "010";
            SHIFT_DR         : return "0100";
            EXIT1_DR         : return "0101";
            PAUSE_DR         : return "01010";
            EXIT2_DR         : return "010101";
            UPDATE_DR        : return "01011";
            SELECT_IR_SCAN   : return "011";
            CAPTURE_IR       : return "0110";
            SHIFT_IR         : return "01100";
            EXIT1_IR         : return "01101";
            PAUSE_IR         : return "011010";
            EXIT2_IR         : return "0110101";
            UPDATE_IR        : return "011011";
            default          : return "";
        endcase
    endfunction

    //------------------------------------------------------------
    // Scans (start and end in Run-Test/Idle, data is sent LSB first)
    //   pause_at : bit index after which the scan goes to Pause (-1 = no pause)
    //------------------------------------------------------------
    task scan(bit is_ir, int length, bit [63:0] data, int pause_at = -1, int pause_cycles = 3);
        bit last;
        if(cur_state != RUN_TEST_IDLE) goto_state(RUN_TEST_IDLE);

        drive(1);                        // Select-DR-Scan
        if(is_ir) drive(1);              // Select-IR-Scan
        drive(0);                        // Capture
        drive(0);                        // Shift

        for(int i = 0; i < length; i++)
        begin
            last = (i == length - 1);
            drive(last || (i == pause_at), data[i]);     // TMS=1 on the last bit -> Exit1
            if(i == pause_at && !last)
            begin
                drive(0);                                // Exit1 -> Pause
                repeat(pause_cycles) drive(0);           // stay in Pause
                drive(1);                                // Pause -> Exit2
                drive(0);                                // Exit2 -> Shift
            end
        end

        drive(1);                        // Exit1 -> Update
        drive(0);                        // Update -> Run-Test/Idle
    endtask

    task scan_ir(bit [3:0] opcode, int pause_at = -1);
        scan(1, 4, {60'd0, opcode}, pause_at);
    endtask

    task scan_dr(int length, bit [63:0] data, int pause_at = -1);
        scan(0, length, data, pause_at);
    endtask

    task load_ir(bit [3:0] opcode);
        scan_ir(opcode);
    endtask

endclass : jtag_base_seqs

`endif
