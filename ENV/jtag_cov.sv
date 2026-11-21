`ifndef JTAG_COV
`define JTAG_COV

//-----------------------------------------------------------------------------
// Functional coverage
//   - all 16 TAP states
//   - all 32 state transitions (state x TMS)
//   - all 16 instruction opcodes + instruction class (IDCODE / BYPASS / unused)
//   - cross: instruction class x DR-scan state
//   - reset, TDI shifted in and TDO shifted out
//-----------------------------------------------------------------------------
class jtag_cov extends uvm_subscriber #(jtag_trans);

    //Factory registration
    `uvm_component_utils(jtag_cov)

    jtag_trans trans_h;

    covergroup jtag_cg;

        //TRST_N asserted / released
        RESET       : coverpoint trans_h.trst_n
                      {
                          bins ASSERTED = {0};
                          bins RELEASED = {1};
                      }

        //every TAP state (one bin per state)
        TAP_STATE   : coverpoint trans_h.tap_state iff (trans_h.trst_n);

        TMS         : coverpoint trans_h.tms iff (trans_h.trst_n);

        //every arc of the state diagram = state x TMS (16 x 2 = 32 bins)
        TRANSITION  : cross TAP_STATE, TMS;

        //every 4-bit opcode loaded into the instruction register
        OPCODE      : coverpoint trans_h.ir_reg iff (trans_h.trst_n)
                      {
                          bins op[] = {[0:15]};
                      }

        //instruction class
        INSTRUCTION : coverpoint trans_h.ir_reg iff (trans_h.trst_n)
                      {
                          bins IDCODE = {IDCODE_OP};
                          bins BYPASS = {BYPASS_OP};
                          bins UNUSED = {4'b0000, [4'b0010:4'b1110]};
                      }

        //states of a DR scan
        DR_STATE    : coverpoint trans_h.tap_state iff (trans_h.trst_n)
                      {
                          bins CAPTURE = {CAPTURE_DR};
                          bins SHIFT   = {SHIFT_DR};
                          bins EXIT1   = {EXIT1_DR};
                          bins PAUSE   = {PAUSE_DR};
                          bins EXIT2   = {EXIT2_DR};
                          bins UPDATE  = {UPDATE_DR};
                      }

        //every instruction class goes through every DR-scan state (3 x 6 = 18 bins)
        INSTR_X_DR  : cross INSTRUCTION, DR_STATE;

        //data shifted in on TDI during Shift-IR / Shift-DR
        TDI_SHIFT   : coverpoint trans_h.tdi iff (trans_h.trst_n && (trans_h.tap_state == SHIFT_IR || trans_h.tap_state == SHIFT_DR))
                      {
                          bins ZERO = {0};
                          bins ONE  = {1};
                      }

        //data shifted out on TDO
        TDO_SHIFT   : coverpoint trans_h.tdo iff (trans_h.trst_n && trans_h.tdo_en)
                      {
                          bins ZERO = {0};
                          bins ONE  = {1};
                      }

    endgroup : jtag_cg

    //Function new - constructor
    function new(string name = "jtag_cov", uvm_component parent = null);
        super.new(name, parent);
        jtag_cg = new();
    endfunction

    //called by the monitor's analysis port for every TCK cycle
    function void write(jtag_trans t);
        trans_h = t;
        jtag_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        $display("-----------------------------------------------------------");
        $display("                 JTAG FUNCTIONAL COVERAGE");
        $display("-----------------------------------------------------------");
        $display(" Reset                   : %6.2f %%", jtag_cg.RESET.get_coverage());
        $display(" TAP states              : %6.2f %%", jtag_cg.TAP_STATE.get_coverage());
        $display(" State transitions       : %6.2f %%", jtag_cg.TRANSITION.get_coverage());
        $display(" Opcodes loaded          : %6.2f %%", jtag_cg.OPCODE.get_coverage());
        $display(" Instruction class       : %6.2f %%", jtag_cg.INSTRUCTION.get_coverage());
        $display(" Instruction x DR state  : %6.2f %%", jtag_cg.INSTR_X_DR.get_coverage());
        $display(" TDI shifted in          : %6.2f %%", jtag_cg.TDI_SHIFT.get_coverage());
        $display(" TDO shifted out         : %6.2f %%", jtag_cg.TDO_SHIFT.get_coverage());
        $display("-----------------------------------------------------------");
        $display(" JTAG - Total Coverage   : %6.2f %%", jtag_cg.get_coverage());
        $display("-----------------------------------------------------------");
    endfunction

endclass : jtag_cov

`endif
