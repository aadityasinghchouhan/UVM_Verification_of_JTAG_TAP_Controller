`ifndef JTAG_BYPASS_SEQS_TC5
`define JTAG_BYPASS_SEQS_TC5

//-----------------------------------------------------------------------------
// TC5 : BYPASS test
//   - TDO = TDI delayed by one TCK, first bit out is 0
//   - different scan lengths (1 to 64 bits)
//   - unused opcodes also select the BYPASS register
//-----------------------------------------------------------------------------
class jtag_bypass_seqs_tc5 extends jtag_base_seqs;

    `uvm_object_utils(jtag_bypass_seqs_tc5)

    function new(string name = "jtag_bypass_seqs_tc5");
        super.new(name);
    endfunction

    task body();
        int len;
        bit [3:0] unused_ops[4] = '{4'b0000, 4'b0010, 4'b0111, 4'b1110};

        reset_by_trst();
        load_ir(BYPASS_OP);

        scan_dr(1,  64'h1);
        scan_dr(2,  64'h3);
        scan_dr(8,  64'hA5);
        scan_dr(32, 64'h1234_5678);
        scan_dr(64, {$urandom, $urandom});

        //random lengths and data
        repeat(10)
        begin
            len = $urandom_range(1, 64);
            scan_dr(len, {$urandom, $urandom});
        end

        //unused opcodes behave like BYPASS
        foreach(unused_ops[i])
        begin
            load_ir(unused_ops[i]);
            scan_dr(16, 64'hBEEF);
        end
    endtask

endclass : jtag_bypass_seqs_tc5

`endif
