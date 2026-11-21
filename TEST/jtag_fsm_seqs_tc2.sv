`ifndef JTAG_FSM_SEQS_TC2
`define JTAG_FSM_SEQS_TC2

//-----------------------------------------------------------------------------
// TC2 : TAP state machine test
//   - one continuous walk that visits all 16 states
//   - every state with TMS=0 and TMS=1 (all 32 transitions)
//   - staying in the states that loop on themselves
//-----------------------------------------------------------------------------
class jtag_fsm_seqs_tc2 extends jtag_base_seqs;

    `uvm_object_utils(jtag_fsm_seqs_tc2)

    function new(string name = "jtag_fsm_seqs_tc2");
        super.new(name);
    endfunction

    task body();
        string      walk;
        tap_state_e s;

        reset_by_trst();

        //1. walk through all 16 states starting from Run-Test/Idle
        walk = "1001011110010111110";
        for(int i = 0; i < walk.len(); i++)
        begin
            drive(walk[i] == "1");
            `uvm_info("TC2_FSM", $sformatf("Walk : TMS=%s -> %s", walk.substr(i, i), cur_state.name()), UVM_LOW)
        end

        //2. every transition : each state with TMS=0 and TMS=1
        for(int i = 0; i < 16; i++)
        begin
            for(int t = 0; t < 2; t++)
            begin
                s = tap_state_e'(i);
                goto_state(s);
                drive(t);
                `uvm_info("TC2_FSM", $sformatf("Transition : %s --TMS=%0d--> %s", s.name(), t, cur_state.name()), UVM_LOW)
            end
        end

        //3. self-loop states
        goto_state(TEST_LOGIC_RESET); repeat(5) drive(1);
        goto_state(RUN_TEST_IDLE);    repeat(5) drive(0);
        goto_state(SHIFT_DR);         repeat(5) drive(0);
        goto_state(PAUSE_DR);         repeat(5) drive(0);
        goto_state(SHIFT_IR);         repeat(5) drive(0);
        goto_state(PAUSE_IR);         repeat(5) drive(0);
        reset_by_trst();
    endtask

endclass : jtag_fsm_seqs_tc2

`endif
