`ifndef JTAG_IDCODE_SEQS_TC4
`define JTAG_IDCODE_SEQS_TC4

//-----------------------------------------------------------------------------
// TC4 : IDCODE test
//   - read IDCODE right after reset (no IR load needed)
//   - read IDCODE after loading the IDCODE instruction
//   - 64-bit scan : IDCODE comes out first, then the TDI data
//   - repeated reads always return the same value
//-----------------------------------------------------------------------------
class jtag_idcode_seqs_tc4 extends jtag_base_seqs;

    `uvm_object_utils(jtag_idcode_seqs_tc4)

    function new(string name = "jtag_idcode_seqs_tc4");
        super.new(name);
    endfunction

    task body();
        reset_by_trst();

        //default instruction after reset
        scan_dr(32, 32'h0);

        //explicit IDCODE instruction
        load_ir(IDCODE_OP);
        scan_dr(32, 32'hFFFF_FFFF);

        //IDCODE followed by the shifted-in data
        scan_dr(64, 64'hDEAD_BEEF_0000_0000);

        //repeated reads with random TDI
        repeat(4) scan_dr(32, {32'd0, $urandom});

        //read only the lower 16 bits
        scan_dr(16, 16'h0);
    endtask

endclass : jtag_idcode_seqs_tc4

`endif
