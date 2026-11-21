`ifndef JTAG_IR_SEQS_TC3
`define JTAG_IR_SEQS_TC3

//-----------------------------------------------------------------------------
// TC3 : Instruction register test
//   - load all 16 opcodes; each IR scan must shift out the capture value 0001
//   - after each load, a DR scan shows which data register was selected
//     (IDCODE for 0001, BYPASS for 1111 and for every unused opcode)
//-----------------------------------------------------------------------------
class jtag_ir_seqs_tc3 extends jtag_base_seqs;

    `uvm_object_utils(jtag_ir_seqs_tc3)

    function new(string name = "jtag_ir_seqs_tc3");
        super.new(name);
    endfunction

    task body();
        reset_by_trst();

        for(int op = 0; op < 16; op++)
        begin
            `uvm_info("TC3_IR", $sformatf("Loading instruction %b", op[3:0]), UVM_LOW)
            load_ir(op[3:0]);
            scan_dr(36, 36'h9_A5C3_F00F);
        end

        //switch BYPASS -> IDCODE -> BYPASS
        load_ir(BYPASS_OP);  scan_dr(8,  8'h5A);
        load_ir(IDCODE_OP);  scan_dr(32, 32'h0);
        load_ir(BYPASS_OP);  scan_dr(8,  8'hC3);
    endtask

endclass : jtag_ir_seqs_tc3

`endif
