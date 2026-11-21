`ifndef JTAG_RANDOM_SEQS_TC6
`define JTAG_RANDOM_SEQS_TC6

//-----------------------------------------------------------------------------
// TC6 : Random test
//   - random instructions with random-length DR scans (some paused)
//   - random TMS / TDI every cycle, with TRST_N asserted ~1% of the time
//-----------------------------------------------------------------------------
class jtag_random_seqs_tc6 extends jtag_base_seqs;

    `uvm_object_utils(jtag_random_seqs_tc6)

    int no_of_random_cycles = 3000;

    function new(string name = "jtag_random_seqs_tc6");
        super.new(name);
    endfunction

    task body();
        int len, pause_at;

        reset_by_trst();

        //random instructions and scans
        repeat(30)
        begin
            load_ir($urandom_range(0, 15));
            len      = $urandom_range(1, 64);
            pause_at = ($urandom_range(0, 1)) ? $urandom_range(0, len - 1) : -1;
            scan_dr(len, {$urandom, $urandom}, pause_at);
        end

        //random TMS / TDI / TRST_N
        repeat(no_of_random_cycles) drive_random();

        //finish with a known good read
        reset_by_trst();
        scan_dr(32, 32'h0);
    endtask

endclass : jtag_random_seqs_tc6

`endif
