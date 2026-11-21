`ifndef JTAG_CORNER_SEQS_TC7
`define JTAG_CORNER_SEQS_TC7

//-----------------------------------------------------------------------------
// TC7 : Corner cases
//-----------------------------------------------------------------------------
class jtag_corner_seqs_tc7 extends jtag_base_seqs;

    `uvm_object_utils(jtag_corner_seqs_tc7)

    function new(string name = "jtag_corner_seqs_tc7");
        super.new(name);
    endfunction

    task body();
        reset_by_trst();

        //1. IR scan paused in the middle (Pause-IR) for a long time
        `uvm_info("TC7_CORNER", "1. IR scan with long pause", UVM_LOW)
        scan(1, 4, BYPASS_OP, 1, 10);
        scan_dr(8, 8'h3C);

        //2. IDCODE read paused after the first bit and near the end
        `uvm_info("TC7_CORNER", "2. IDCODE read with pause", UVM_LOW)
        load_ir(IDCODE_OP);
        scan_dr(32, 32'h0, 0);
        scan_dr(32, 32'h0, 30);

        //3. BYPASS and an unused opcode with pause
        `uvm_info("TC7_CORNER", "3. BYPASS / unused opcode with pause", UVM_LOW)
        load_ir(BYPASS_OP);
        scan_dr(16, 16'h5AA5, 7);
        load_ir(4'b0110);
        scan_dr(16, 16'hC3C3, 3);

        //4. 1-bit IDCODE read : only the LSB (always 1)
        `uvm_info("TC7_CORNER", "4. 1-bit IDCODE read", UVM_LOW)
        load_ir(IDCODE_OP);
        scan_dr(1, 0);

        //5. IR scan longer than 4 bits : only the last 4 bits stay in the IR
        `uvm_info("TC7_CORNER", "5. 8-bit IR scan (last 4 bits = BYPASS)", UVM_LOW)
        scan(1, 8, 8'b1111_0001);
        scan_dr(4, 4'b1010);

        //6. Capture then Exit1 without shifting
        `uvm_info("TC7_CORNER", "6. Capture -> Exit1 -> Update with no shift", UVM_LOW)
        drive(1); drive(0); drive(1); drive(1); drive(0);              // DR : no shift
        drive(1); drive(1); drive(0); drive(1); drive(1); drive(0);    // IR : loads capture value 0001 = IDCODE
        scan_dr(32, 32'h0);

        //7. Exit2 directly to Update (leave Pause without shifting again)
        `uvm_info("TC7_CORNER", "7. Pause -> Exit2 -> Update", UVM_LOW)
        drive(1); drive(0); drive(0);                                  // Shift-DR
        drive(0, 1); drive(0, 0); drive(1, 1);                         // 3 bits, last one -> Exit1
        drive(0); drive(0);                                            // Pause
        drive(1);                                                      // Exit2
        drive(1);                                                      // Update
        drive(0);                                                      // Idle

        //8. Back-to-back DR scans : Update-DR -> Select-DR without Idle
        `uvm_info("TC7_CORNER", "8. Back-to-back DR scans", UVM_LOW)
        drive(1); drive(0); drive(0);                                  // Shift-DR
        for(int i = 0; i < 32; i++) drive(i == 31, 0);                 // read IDCODE
        drive(1);                                                      // Update-DR
        drive(1); drive(0); drive(0);                                  // Select-DR, Capture, Shift
        for(int i = 0; i < 32; i++) drive(i == 31, 1);                 // read IDCODE again
        drive(1); drive(0);                                            // Update, Idle

        //9. Back-to-back IR scans : Update-IR -> Select-DR -> Select-IR
        `uvm_info("TC7_CORNER", "9. Back-to-back IR scans", UVM_LOW)
        drive(1); drive(1); drive(0); drive(0);                        // Shift-IR
        for(int i = 0; i < 4; i++) drive(i == 3, 1);                   // BYPASS
        drive(1);                                                      // Update-IR
        drive(1); drive(1); drive(0); drive(0);                        // Select-DR, Select-IR, Capture, Shift
        for(int i = 0; i < 4; i++) drive(i == 3, IDCODE_OP[i]);        // IDCODE
        drive(1); drive(0);                                            // Update-IR, Idle
        scan_dr(32, 32'h0);

        //10. TRST_N in the middle of Shift-DR aborts the scan
        `uvm_info("TC7_CORNER", "10. TRST_N during Shift-DR", UVM_LOW)
        load_ir(BYPASS_OP);
        drive(1); drive(0); drive(0);
        repeat(5) drive(0, 1);
        drive(0, 0, 0);                                                // asynchronous reset
        drive(0);
        scan_dr(32, 32'h0);                                            // IDCODE selected again

        //11. TRST_N in the middle of Shift-IR : instruction is not updated
        `uvm_info("TC7_CORNER", "11. TRST_N during Shift-IR", UVM_LOW)
        drive(1); drive(1); drive(0); drive(0);
        drive(0, 1); drive(0, 1);
        drive(0, 0, 0);
        drive(0);
        scan_dr(32, 32'h0);

        //12. TMS reset in the middle of Shift-DR
        `uvm_info("TC7_CORNER", "12. TMS reset during Shift-DR", UVM_LOW)
        load_ir(BYPASS_OP);
        drive(1); drive(0); drive(0);
        repeat(3) drive(0, 1);
        reset_by_tms();
        scan_dr(32, 32'h0);

        //13. Long stay in Test-Logic-Reset and Run-Test/Idle
        `uvm_info("TC7_CORNER", "13. Long Test-Logic-Reset / Run-Test-Idle", UVM_LOW)
        repeat(10) drive(1);
        idle(10);
        scan_dr(32, 32'h0);
    endtask

endclass : jtag_corner_seqs_tc7

`endif
