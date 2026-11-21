# JTAG TAP Controller – Design and UVM Verification

IEEE 1149.1 TAP controller in SystemVerilog, verified with a UVM testbench,
SystemVerilog assertions and functional coverage. Simulator: QuestaSim
(built-in UVM library).

## Folder structure

| Folder | Files | Contents |
|---|---|---|
| `RTL`  | `jtag_tap.sv` | TAP controller (DUT) |
| `ENV`  | `jtag_if.sv`, `jtag_defines.sv`, `jtag_config.sv`, `jtag_trans.sv`, `jtag_base_seqs.sv`, `jtag_seqr.sv`, `jtag_drv.sv`, `jtag_mon.sv`, `jtag_agent.sv`, `jtag_sb.sv`, `jtag_cov.sv`, `jtag_env.sv` | UVM environment |
| `TEST` | `jtag_pkg.sv`, `jtag_base_test.sv`, `*_seqs_tcN.sv`, `*_tcN.sv` | Package, test sequences and test cases |
| `TOP`  | `jtag_top.sv`, `jtag_sva.sv` | Testbench top and assertions (bound to the DUT) |
| `SIM`  | `Makefile`, `run.do` | Compile / run / coverage scripts |

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
* Coverage: states (16), transitions (32), opcodes (16), instruction class (3),
  instruction class x DR-scan state (18), reset, TDI/TDO data.

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

## How to run (from the `SIM` folder)

```
make run_tc1        # compile + run test case 1 (same for run_tc2 ... run_tc8)
make regress        # compile + run all test cases
make run_merge      # all test cases with coverage, merged HTML report
make help           # list of all targets
```

Without `make`:

```
vlib work
vlog -sv +cover=bcesf ../RTL/jtag_tap.sv ../TEST/jtag_pkg.sv ../TOP/jtag_sva.sv ../TOP/jtag_top.sv +incdir+../ENV +incdir+../TEST +incdir+../TOP
vsim -vopt jtag_top -c -do "run -all; exit" +UVM_TESTNAME=jtag_reset_tc1 -l tc1_reset.log
```

## Output

Each test writes a log (`tcN_*.log`) with every IR/DR scan result, a scoreboard summary
(`TEST PASSED` / `TEST FAILED`), the functional coverage per coverpoint, and the UVM report
summary. `make run_merge` also produces `mergecov.ucdb`, `coverage_report.txt` and the
`covhtmlreport` folder.
