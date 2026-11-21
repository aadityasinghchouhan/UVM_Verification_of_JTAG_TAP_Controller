`ifndef JTAG_RESET_SEQS_TC1
`define JTAG_RESET_SEQS_TC1

//-----------------------------------------------------------------------------
// TC1 : Reset test
//   - TRST_N reset selects IDCODE
//   - TRST_N and 5 x TMS=1 both restore IDCODE after BYPASS was loaded
//   - 5 x TMS=1 reaches Test-Logic-Reset from EVERY state
//   - TRST_N resets the TAP from EVERY state
//-----------------------------------------------------------------------------
class jtag_reset_seqs_tc1 extends jtag_base_seqs;

    `uvm_object_utils(jtag_reset_seqs_tc1)

    function new(string name = "jtag_reset_seqs_tc1");
        super.new(name);
    endfunction

    task body();
        tap_state_e s;

        //1. TRST_N reset -> default instruction is IDCODE
        reset_by_trst();
        scan_dr(32, 32'h0);

        //2. load BYPASS, then TRST_N -> IDCODE again
        load_ir(BYPASS_OP);
        reset_by_trst();
        scan_dr(32, 32'h0);

        //3. load BYPASS, then 5 x TMS=1 -> IDCODE again
        load_ir(BYPASS_OP);
        reset_by_tms();
        scan_dr(32, 32'h0);

        //4. TMS reset from every state
        for(int i = 0; i < 16; i++)
        begin
            s = tap_state_e'(i);
            goto_state(s);
            `uvm_info("TC1_RESET", $sformatf("TMS reset (5 x TMS=1) from state %s", s.name()), UVM_LOW)
            reset_by_tms();
        end

        //5. TRST_N reset from every state
        for(int i = 0; i < 16; i++)
        begin
            s = tap_state_e'(i);
            goto_state(s);
            `uvm_info("TC1_RESET", $sformatf("TRST_N reset from state %s", s.name()), UVM_LOW)
            reset_by_trst();
        end

        //6. TRST_N held low for several cycles while TMS/TDI toggle
        repeat(3) drive(0, 1, 0);
        repeat(3) drive(1, 0, 0);
        drive(0);
        scan_dr(32, 32'h0);
    endtask

endclass : jtag_reset_seqs_tc1

`endif
