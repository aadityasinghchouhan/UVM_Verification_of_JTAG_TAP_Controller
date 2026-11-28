# How to Run – JTAG TAP Controller UVM Verification

This guide explains how to compile and run the project in QuestaSim and how to check the results.
The main check is **one command** (Section 3) and takes about 1–2 minutes.

---

## 1. Requirements

| Item | Details |
|---|---|
| Simulator | Siemens QuestaSim (tested on **QuestaSim 10.7c, Windows**). QuestaSim 10.6 or newer should work. |
| UVM library | The **UVM library built into QuestaSim** is used. Nothing to download or install. |
| C compiler | **Not needed.** |
| `make` | **Not needed** (optional, Section 8). |

> Do **not** compile your own copy of UVM or pass `+incdir+<uvm path>`. The project uses QuestaSim's built-in UVM, the same way as the course lab projects.

---

## 2. Get the project

**Option A – Git**
```
git clone https://github.com/aadityasinghchouhan/UVM_Verification_of_JTAG_TAP_Controller.git
```

**Option B – ZIP**
On the GitHub page click **Code → Download ZIP** and unzip it.

Folder structure:
```
UVM_Verification_of_JTAG_TAP_Controller/
├── RTL/       jtag_tap.sv                         (design)
├── ENV/       interface, agent, driver, monitor, scoreboard, coverage, env
├── TEST/      jtag_pkg.sv, base test, test cases TC1–TC8 and their sequences
├── TOP/       jtag_top.sv (testbench top), jtag_sva.sv (assertions + cover properties)
├── BUGS/      jtag_tap_bug1.sv ... jtag_tap_bug7.sv (bug-injection copies of the RTL)
├── SIM/       run_all.do, run_cov.do, run_bugs.do, run_seeds.do, Makefile, run.do
│                                                  <-- ALL COMMANDS ARE RUN FROM HERE
├── RESULTS/   regression/, coverage/, bug_injection/, seeds/  (written by the scripts)
├── README.md
└── HOW_TO_RUN.md
```

> **Important:** every command below must be run from inside the **`SIM`** folder, because the scripts use relative paths such as `../RTL/jtag_tap.sv`.

---

## 3. Quick run – all tests with ONE command (recommended)

### Option A – from a terminal (Windows PowerShell / Command Prompt, or Linux shell)
```
cd <path-to-project>/SIM
vsim -c -do run_all.do
```

### Option B – from the QuestaSim GUI
1. Open QuestaSim.
2. **File → Change Directory…** and select the project's **`SIM`** folder.
3. In the **Transcript** window type:
   ```
   do run_all.do
   ```

### Expected result
```
======================== JTAG TAP REGRESSION SUMMARY ========================
  TEST                    RESULT        UVM_ERROR       FUNCTIONAL COVERAGE
  jtag_base_test          TEST PASSED   0               ... %
  jtag_reset_tc1          TEST PASSED   0               ... %
  ...
  jtag_regression_tc8     TEST PASSED   0               100.00 %
=============================================================================
  OVERALL : ALL 9 TESTS PASSED
=============================================================================
```
* Every test must show **TEST PASSED** and **UVM_ERROR 0**.
* **`jtag_regression_tc8` shows 100.00 % functional coverage.** Single tests show lower
  coverage on their own because each one targets one feature.
* Logs: `RESULTS/regression/<test name>.log`. Summary: `RESULTS/regression/regression_summary.txt`.

---

## 4. Other scripts (optional)

All run from the **`SIM`** folder, the same way as Section 3 (`vsim -c -do <script>` in a
terminal, or `do <script>` in the GUI Transcript).

| Script | What it does | Time | Result file |
|---|---|---|---|
| `run_cov.do` | Runs TC1–TC7 with coverage, merges them, writes text + HTML reports. Code coverage is collected on the design only. **Needs a coverage license.** | ~2 min | `RESULTS/coverage/coverage_summary.txt`, `coverage_report.txt`, `covhtmlreport/index.html` |
| `run_bugs.do` | Bug-injection experiment: compiles each of the 7 buggy copies in `BUGS/` and runs the full regression on it. Every bug must be **DETECTED**. | ~5 min | `RESULTS/bug_injection/bug_summary.txt` |
| `run_seeds.do` | Runs the random test (TC6) with 10 different seeds. Every seed must pass. | ~2 min | `RESULTS/seeds/seeds_summary.txt` |

**Expected `run_bugs.do` result:** a table with 7 rows, each ending in `DETECTED`, and
`DETECTED : 7 of 7 bugs`. These runs are *supposed* to show errors – that is how the
testbench proves it catches the bug. `run_bugs.do` deletes the `work` library at the end
(it held a buggy design), so run `run_all.do` again before running single tests.

---

## 5. Run one test at a time

From the **`SIM`** folder:
```
vlib work
vlog -sv +cover=bcesft ../RTL/jtag_tap.sv
vlog -sv ../TEST/jtag_pkg.sv ../TOP/jtag_sva.sv ../TOP/jtag_top.sv +incdir+../ENV +incdir+../TEST +incdir+../TOP
```
Both compile steps must end with `Errors: 0`. Then run a test (change the test name as needed):
```
vsim -vopt jtag_top -c -do "run -all; exit" +UVM_TESTNAME=jtag_reset_tc1 -l tc1_reset.log
```

| TC | Test name (`+UVM_TESTNAME=`) | What it checks |
|---|---|---|
| base | `jtag_base_test` | Smoke test: reset, read IDCODE, BYPASS |
| 1 | `jtag_reset_tc1` | TRST_N reset and 5 x TMS=1 reset from every state; IDCODE selected after reset |
| 2 | `jtag_fsm_tc2` | All 16 states and all 32 state transitions |
| 3 | `jtag_ir_tc3` | Load all 16 opcodes, IR capture value `0001`, selected data register |
| 4 | `jtag_idcode_tc4` | IDCODE after reset and after loading IDCODE, 64-bit scan, repeated reads |
| 5 | `jtag_bypass_tc5` | 1-bit delay through BYPASS, lengths 1–64, unused opcodes act as BYPASS |
| 6 | `jtag_random_tc6` | Random instructions and scans, random TMS / TDI / TRST_N |
| 7 | `jtag_corner_tc7` | Pause/resume, long pause, Exit2→Update, back-to-back scans, 8-bit IR scan, reset during shift |
| 8 | `jtag_regression_tc8` | TC1–TC7 in one simulation → **100 % functional coverage** |

---

## 6. How to read a log file

Each log contains:

1. **Every IR / DR scan checked by the scoreboard**, for example:
   ```
   [JTAG_SB] DR SCAN #2 : register = IDCODE | length = 32 | TDI in = 0x0 | TDO out = 0x1cafe157 | expected = 0x1cafe157 --> MATCH
   ```
2. **Scoreboard summary** – must end with `RESULT : TEST PASSED`.
3. **Functional coverage** – per coverpoint and `JTAG - Total Coverage`.
4. **Assertion cover summary** – how many times each checked situation happened (all should be above 0 in TC8).
5. **UVM report summary** – must show `UVM_ERROR : 0` and `UVM_FATAL : 0`.

If an assertion fails, QuestaSim prints `** Error: A_<NAME> : ...` – in a normal run there should be **none**.

---

## 7. Waveforms (optional)

From the **`SIM`** folder, after compiling (Section 5):
```
vsim -vopt -voptargs=+acc jtag_top -do run.do +UVM_TESTNAME=jtag_corner_tc7
```
`run.do` adds the JTAG pins, the FSM state, the instruction register, the IDCODE / BYPASS
registers and the control signals.

---

## 8. Makefile (optional – Linux, or Windows with `make` installed)

From the **`SIM`** folder:
```
make help          # list of all targets
make regress       # same as run_all.do
make coverage      # same as run_cov.do
make bugs          # same as run_bugs.do
make seeds         # same as run_seeds.do
make everything    # all four
make run_tc1       # compile + run test case 1 (run_tc2 ... run_tc8 the same way)
```

---

## 9. Troubleshooting

| Message | Cause | Fix |
|---|---|---|
| `invalid command name "run_all.do"` | The script was not found – wrong folder | `cd` into `SIM` and run again |
| `Cannot find path ../RTL/...` or `Failed to open file` | Command not run from the `SIM` folder | `cd` into `SIM` and run again |
| `vsim-7019: Can't locate a C/C++ compiler for 'DPI Export Compilation'` | A self-compiled UVM library is being used | Delete the `work` folder and compile **without** any `+incdir+<uvm path>` or `uvm_pkg.sv`; QuestaSim's built-in UVM is used automatically |
| `Could not find field/method name (record_field_int)` | Mixed UVM versions | Same fix as above |
| `Design unit jtag_top not found` | Compile step skipped, or `run_bugs.do` deleted `work` | Run `run_all.do`, or the compile steps in Section 5 |
| Warning that `-vopt` is deprecated | Newer QuestaSim versions | Harmless – the test still runs |
| Coverage license error in `run_cov.do` | No coverage license | Skip it; functional coverage is still printed in every log |
