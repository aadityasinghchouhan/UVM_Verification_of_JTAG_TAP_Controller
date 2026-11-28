# JTAG TAP Controller – Design and UVM Verification

IEEE 1149.1 TAP controller in SystemVerilog, verified with a UVM testbench,
SystemVerilog assertions, functional and code coverage, and a bug-injection
experiment. Simulator: QuestaSim (built-in UVM library).

## Folder structure

| Folder | Files | Contents |
|---|---|---|
| `RTL`  | `jtag_tap.sv` | TAP controller (DUT) |
| `ENV`  | `jtag_if.sv`, `jtag_defines.sv`, `jtag_config.sv`, `jtag_trans.sv`, `jtag_base_seqs.sv`, `jtag_seqr.sv`, `jtag_drv.sv`, `jtag_mon.sv`, `jtag_agent.sv`, `jtag_sb.sv`, `jtag_cov.sv`, `jtag_env.sv` | UVM environment |
| `TEST` | `jtag_pkg.sv`, `jtag_base_test.sv`, `*_seqs_tcN.sv`, `*_tcN.sv` | Package, test sequences and test cases |
| `TOP`  | `jtag_top.sv`, `jtag_sva.sv` | Testbench top, assertions and cover properties (bound to the DUT) |
| `BUGS` | `jtag_tap_bug1.sv` … `jtag_tap_bug7.sv` | Copies of the RTL, each with one deliberate bug (bug-injection experiment) |
| `SIM`  | `run_all.do`, `run_cov.do`, `run_bugs.do`, `run_seeds.do`, `Makefile`, `run.do` | Run scripts |
| `RESULTS` | `regression/`, `coverage/`, `bug_injection/`, `seeds/` | Logs and summary files written by the scripts |

## Design (RTL)

* 16-state TAP FSM controlled by TMS, active-low asynchronous TRST_N
* 4-bit instruction register; capture value `0001`
* Instructions: `IDCODE = 0001` (default after reset), `BYPASS = 1111`; any other opcode selects BYPASS
* Data registers: 1-bit BYPASS, 32-bit IDCODE (`0x1CAFE157`)
* Capture / Shift on the rising edge of TCK; Update-IR, TDO and TDO enable on the falling edge
* Control outputs: test_logic_reset, run_test_idle, capture/shift/update for IR and DR

## Testbench

* One active agent (sequencer, driver, monitor). One transaction = one TCK cycle.
* Driver changes TMS/TDI/TRST_N after the falling edge; monitor samples before the rising edge.
* Scoreboard contains a reference model of the TAP. Every cycle it checks state,
  instruction, TDO enable and TDO, and every complete IR/DR scan is checked against the
  expected captured value followed by the shifted-in data.
* Functional coverage: states (16), transitions (32), opcodes (16), instruction class (3),
  instruction class x DR-scan state (18), reset, TDI/TDO data.
* Code coverage (statement, branch, condition, expression, FSM, toggle) is collected on the design only.

## Assertions (`TOP/jtag_sva.sv`)

1. `A_TRST_RESET` – TRST_N puts the TAP in Test-Logic-Reset with IDCODE selected
2. `A_TMS_5_RESET` – five TMS=1 clocks reach Test-Logic-Reset from any state
3. `A_LEGAL_TRANSITION` – every state change follows the state diagram
4. `A_IR_CAPTURE` – Capture-IR loads `01` into the IR LSBs
5. `A_IR_UPDATE` – Update-IR loads the shifted instruction
6. `A_IR_STABLE` – instruction changes only in Update-IR / Test-Logic-Reset
7. `A_IDCODE_CAPTURE` – Capture-DR with IDCODE loads the IDCODE value
8. `A_BYPASS_CAPTURE` – Capture-DR with BYPASS loads 0
9. `A_TDO_ENABLE` – TDO enabled only in Shift-IR / Shift-DR
10. `A_TDO_FALLING_EDGE` – TDO changes only on the falling edge of TCK
11. `A_TLR_IDCODE` – Test-Logic-Reset (TMS reset) selects IDCODE
12. `A_IR_SHIFT` – Shift-IR shifts TDI in at the MSB
13. `A_DR_SELECT` – the IDCODE register does not change when it is not selected

Assertions 11–13 were added after the bug-injection experiment showed that bugs 4, 6
and 7 were caught only by the scoreboard. Each assertion also has a **cover property**;
the cover counts are printed at the end of every log (`ASSERTION COVER SUMMARY`) to show
that every checked situation really happened.

## Test cases

| TC | Test name | What it checks |
|---|---|---|
| base | `jtag_base_test` | Smoke: reset, read IDCODE, BYPASS |
| 1 | `jtag_reset_tc1` | TRST_N and 5 x TMS=1 reset from every state, IDCODE restored |
| 2 | `jtag_fsm_tc2` | Walk through all 16 states, all 32 transitions, self-loops |
| 3 | `jtag_ir_tc3` | Load all 16 opcodes, IR capture value, selected data register |
| 4 | `jtag_idcode_tc4` | IDCODE after reset / after load, 64-bit scan, repeated reads |
| 5 | `jtag_bypass_tc5` | 1-bit delay, scan lengths 1–64, unused opcodes as BYPASS |
| 6 | `jtag_random_tc6` | Random instructions/scans and random TMS/TDI/TRST_N |
| 7 | `jtag_corner_tc7` | Pause/resume, long pause, Exit2→Update, back-to-back scans, 8-bit IR scan, reset during shift |
| 8 | `jtag_regression_tc8` | TC1–TC7 in one simulation (100 % functional coverage) |

## Bug injection (`BUGS/`, `SIM/run_bugs.do`)

| Bug | Deliberate design error |
|---|---|
| 1 | IDCODE capture value wrong (bit 8 flipped) |
| 2 | Pause-DR with TMS=1 goes to Update-DR instead of Exit2-DR |
| 3 | TDO enable decoded from the next state (early) |
| 4 | TMS reset does not restore the IDCODE instruction |
| 5 | BYPASS register captures 1 instead of 0 |
| 6 | Instruction register shifts in the wrong direction |
| 7 | Unused opcodes select IDCODE instead of BYPASS |

`run_bugs.do` compiles each buggy copy and runs the full regression (TC8). The result for every
bug (scoreboard errors and assertions that fired) is in `RESULTS/bug_injection/bug_summary.txt`.
The real design in `RTL/` is never modified.

## How to run

**Full step-by-step instructions: [HOW_TO_RUN.pdf](HOW_TO_RUN.pdf)**

All scripts run from the `SIM` folder:

| Command | What it does | Result file |
|---|---|---|
| `vsim -c -do run_all.do` | Compile and run all 9 tests | `RESULTS/regression/regression_summary.txt` |
| `vsim -c -do run_cov.do` | Merged coverage (functional + code + assertions) | `RESULTS/coverage/coverage_summary.txt` |
| `vsim -c -do run_bugs.do` | Bug-injection experiment | `RESULTS/bug_injection/bug_summary.txt` |
| `vsim -c -do run_seeds.do` | Random test with 10 seeds | `RESULTS/seeds/seeds_summary.txt` |

Every test must show `TEST PASSED` and `UVM_ERROR = 0`; `jtag_regression_tc8` shows 100 % functional coverage.
