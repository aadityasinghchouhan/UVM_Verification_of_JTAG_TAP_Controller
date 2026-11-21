`ifndef JTAG_SB
`define JTAG_SB

//-----------------------------------------------------------------------------
// Scoreboard with a reference model of the TAP controller.
//
// Every TCK cycle (sampled just before the rising edge):
//   1) Compare the DUT (state, instruction, TDO enable, TDO) with the model
//   2) Advance the model: rising-edge actions, next state, falling-edge actions
//
// Every complete IR / DR scan (Capture -> Shift ... -> Update) is also checked
// against the specification: first the captured value comes out on TDO,
// then the bits that were shifted in on TDI.
//-----------------------------------------------------------------------------
class jtag_sb extends uvm_scoreboard;

    //Factory registration
    `uvm_component_utils(jtag_sb)

    //Analysis fifo connected to the monitor
    uvm_tlm_analysis_fifo #(jtag_trans) mon_analysis_fifo;

    jtag_trans trans_h;

    //---------------- reference model ----------------
    tap_state_e exp_state;
    bit [3:0]   exp_ir;          // active instruction
    bit [3:0]   exp_ir_shift;    // IR shift stage
    bit [31:0]  exp_idcode;      // IDCODE shift register
    bit         exp_bypass;      // BYPASS register
    bit         reset_seen;      // checking starts after the first reset

    //---------------- scan recording -----------------
    bit         scan_active;
    bit         scan_is_ir;
    bit [3:0]   scan_instr;      // instruction that selected the DR
    bit         scan_in_q[$];    // bits shifted in on TDI
    bit         scan_out_q[$];   // bits shifted out on TDO

    //---------------- statistics ---------------------
    int unsigned cycles_checked;
    int unsigned cycle_mismatches;
    int unsigned ir_scans, dr_scans;
    int unsigned scans_passed, scans_failed;

    //Function new - constructor
    function new(string name = "jtag_sb", uvm_component parent = null);
        super.new(name, parent);
        mon_analysis_fifo = new("mon_analysis_fifo", this);
    endfunction

    task run_phase(uvm_phase phase);
        forever
        begin
            mon_analysis_fifo.get(trans_h);
            process_cycle(trans_h);
        end
    endtask

    //------------------------------------------------------------
    // Per-cycle checking and model update
    //------------------------------------------------------------
    function void process_cycle(jtag_trans t);
        bit exp_tdo;

        //wait for the first reset before checking anything
        if(!reset_seen)
        begin
            if(t.trst_n) return;
            reset_seen = 1;
        end

        cycles_checked++;

        //TRST_N asserted: DUT must be in reset
        if(!t.trst_n)
        begin
            reset_model();
            compare_value("TAP STATE",   t.tap_state, exp_state);
            compare_value("INSTRUCTION", t.ir_reg,    exp_ir);
            compare_value("TDO ENABLE",  t.tdo_en,    1'b0);
            return;
        end

        //1) compare DUT with model
        compare_value("TAP STATE",   t.tap_state, exp_state);
        compare_value("INSTRUCTION", t.ir_reg,    exp_ir);
        compare_value("TDO ENABLE",  t.tdo_en,    (exp_state == SHIFT_IR) || (exp_state == SHIFT_DR));

        if(exp_state == SHIFT_IR)
        begin
            exp_tdo = exp_ir_shift[0];
            compare_value("TDO (IR)", t.tdo, exp_tdo);
        end
        else if(exp_state == SHIFT_DR)
        begin
            exp_tdo = (exp_ir == IDCODE_OP) ? exp_idcode[0] : exp_bypass;
            compare_value("TDO (DR)", t.tdo, exp_tdo);
        end

        //record scan data (bit goes in on TDI, bit comes out on TDO)
        if(scan_active && (exp_state == SHIFT_IR || exp_state == SHIFT_DR))
        begin
            scan_in_q.push_back(t.tdi);
            scan_out_q.push_back(t.tdo);
        end

        //2) rising edge actions of the model
        case(exp_state)
            CAPTURE_IR : begin
                exp_ir_shift = IR_CAPTURE_VALUE;
                start_scan(1);
            end
            SHIFT_IR   : exp_ir_shift = {t.tdi, exp_ir_shift[3:1]};
            CAPTURE_DR : begin
                if(exp_ir == IDCODE_OP) exp_idcode = EXPECTED_IDCODE;
                else                    exp_bypass = 1'b0;
                start_scan(0);
            end
            SHIFT_DR   : begin
                if(exp_ir == IDCODE_OP) exp_idcode = {t.tdi, exp_idcode[31:1]};
                else                    exp_bypass = t.tdi;
            end
            default    : ;
        endcase

        exp_state = tap_next_state(exp_state, t.tms);

        //3) falling edge actions of the model
        if(exp_state == TEST_LOGIC_RESET)
            exp_ir = IDCODE_OP;
        else if(exp_state == UPDATE_IR)
            exp_ir = exp_ir_shift;

        //a scan ends when the TAP enters Update-IR / Update-DR
        if(scan_active && (exp_state == UPDATE_IR || exp_state == UPDATE_DR))
            finish_scan();
    endfunction

    function void reset_model();
        exp_state    = TEST_LOGIC_RESET;
        exp_ir       = IDCODE_OP;
        exp_ir_shift = IR_CAPTURE_VALUE;
        exp_idcode   = 32'd0;
        exp_bypass   = 1'b0;
        scan_active  = 0;            // a reset aborts any scan in progress
        scan_in_q.delete();
        scan_out_q.delete();
    endfunction

    function void compare_value(string what, bit [31:0] actual, bit [31:0] expected);
        if(actual !== expected)
        begin
            cycle_mismatches++;
            `uvm_error("JTAG_SB", $sformatf("Cycle %0d [%s] %s MISMATCH : DUT = 0x%0h, Expected = 0x%0h",
                       cycles_checked, exp_state.name(), what, actual, expected))
        end
    endfunction

    //------------------------------------------------------------
    // Scan level checking
    //------------------------------------------------------------
    function void start_scan(bit is_ir);
        scan_active = 1;
        scan_is_ir  = is_ir;
        scan_instr  = exp_ir;
        scan_in_q.delete();
        scan_out_q.delete();
    endfunction

    function void finish_scan();
        int         reg_len;
        bit [31:0]  capture_val;
        bit         exp_bit;
        bit         ok;
        bit [63:0]  data_in, data_out, data_exp;
        string      kind, status, note;

        scan_active = 0;
        if(scan_out_q.size() == 0) return;          // no bit was shifted

        //what must come out first: the captured value of the selected register
        if(scan_is_ir)
        begin
            reg_len = 4;  capture_val = IR_CAPTURE_VALUE;  kind = "IR";  ir_scans++;
        end
        else if(scan_instr == IDCODE_OP)
        begin
            reg_len = 32; capture_val = EXPECTED_IDCODE;   kind = "DR";  dr_scans++;
        end
        else
        begin
            reg_len = 1;  capture_val = 0;                 kind = "DR";  dr_scans++;
        end

        ok = 1;
        data_in = 0; data_out = 0; data_exp = 0;
        foreach(scan_out_q[i])
        begin
            exp_bit = (i < reg_len) ? capture_val[i] : scan_in_q[i - reg_len];
            if(scan_out_q[i] != exp_bit) ok = 0;
            if(i < 64)
            begin
                data_in[i]  = scan_in_q[i];
                data_out[i] = scan_out_q[i];
                data_exp[i] = exp_bit;
            end
        end

        if(ok) begin scans_passed++; status = "MATCH"; end
        else   begin scans_failed++; status = "MIS-MATCH"; end

        note = (scan_out_q.size() > 64) ? " (first 64 bits shown)" : "";

        if(scan_is_ir)
            `uvm_info("JTAG_SB", $sformatf("IR SCAN #%0d : length = %0d | TDI in = 0x%0h | TDO out = 0x%0h | expected = 0x%0h | new instruction = %b (%s) --> %s%s",
                      ir_scans, scan_out_q.size(), data_in, data_out, data_exp, exp_ir, instr_name(exp_ir), status, note), UVM_LOW)
        else
            `uvm_info("JTAG_SB", $sformatf("DR SCAN #%0d : register = %s | length = %0d | TDI in = 0x%0h | TDO out = 0x%0h | expected = 0x%0h --> %s%s",
                      dr_scans, (scan_instr == IDCODE_OP) ? "IDCODE" : "BYPASS", scan_out_q.size(), data_in, data_out, data_exp, status, note), UVM_LOW)

        if(!ok)
            `uvm_error("JTAG_SB", $sformatf("%s scan #%0d data does not match the specification", kind, scan_is_ir ? ir_scans : dr_scans))
    endfunction

    function string instr_name(bit [3:0] op);
        if(op == IDCODE_OP)      return "IDCODE";
        else if(op == BYPASS_OP) return "BYPASS";
        else                     return "UNUSED -> BYPASS";
    endfunction

    //------------------------------------------------------------
    // Final summary
    //------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        $display("-----------------------------------------------------------");
        $display("                 JTAG SCOREBOARD SUMMARY");
        $display("-----------------------------------------------------------");
        $display(" TCK cycles checked     : %0d", cycles_checked);
        $display(" Cycle mismatches       : %0d", cycle_mismatches);
        $display(" IR scans checked       : %0d", ir_scans);
        $display(" DR scans checked       : %0d", dr_scans);
        $display(" Scans matched          : %0d", scans_passed);
        $display(" Scans mis-matched      : %0d", scans_failed);
        if(cycles_checked != 0 && cycle_mismatches == 0 && scans_failed == 0)
            $display(" RESULT                 : TEST PASSED");
        else
            $display(" RESULT                 : TEST FAILED");
        $display("-----------------------------------------------------------");
    endfunction

endclass : jtag_sb

`endif
