# How to Run – JTAG TAP Controller UVM Verification

This guide explains how to compile and run the project in QuestaSim and how to check the results.
Running everything takes one command (Section 3) and about 1–2 minutes.

---

## 1. Requirements

| Item | Details |
|---|---|
| Simulator | Siemens QuestaSim (tested on **QuestaSim 10.7c, Windows**). Any QuestaSim / ModelSim-Questa 10.6 or newer should work. |
| UVM library | The **UVM library built into QuestaSim** is used. Nothing to download or install. |
| C compiler | **Not needed.** |
| `make` | **Not needed** (optional, only for the Makefile in Section 7). |

> Do **not** compile your own copy of UVM or pass `+incdir+<uvm path>`. The project uses QuestaSim's built-in UVM, exactly like the course lab projects.

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
├── RTL/       jtag_tap.sv                    (design)
├── ENV/       interface, agent, driver, monitor, scoreboard, coverage, env
├── TEST/      jtag_pkg.sv, base test, test cases TC1–TC8 and their sequences
├── TOP/       jtag_top.sv (testbench top), jtag_sva.sv (assertions)
├── SIM/       run_all.do, Makefile, run.do     <-- ALL COMMANDS ARE RUN FROM HERE
├── RESULTS/   logs and coverage report from my own runs
├── README.md
└── HOW_TO_RUN.md
```

> **Important:** every command below must be run from inside the **`SIM`** folder, because the scripts use relative paths such as `../RTL/jtag_tap.sv`.

---

## 3. Quick run – everything with ONE command (recommended)

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

### What `run_all.do` does
1. Creates a fresh `work` library.
2. Compiles the RTL, the UVM testbench and the assertions.
3. Runs all 9 tests one after another. Each test writes its own log file, e.g. `jtag_reset_tc1.log`.
4. Prints a summary table.

### Expected result
At the end you should see:
```
======================== JTAG TAP REGRESSION SUMMARY ========================
  jtag_base_test          TEST PASSED   UVM_ERROR = 0    coverage = ... %
  jtag_reset_tc1          TEST PASSED   UVM_ERROR = 0    coverage = ... %
  ...
  jtag_regression_tc8     TEST PASSED   UVM_ERROR = 0    coverage = 100.00 %
=============================================================================
```
* Every test must show **TEST PASSED** and **UVM_ERROR = 0**.
* **`jtag_regression_tc8` shows 100.00 % functional coverage.**
  The single tests show lower coverage on their own – that is expected, each one targets one feature.

---

## 4. Run one test at a time

From the **`SIM`** folder:

```
vlib work
vlog -sv +cover=bcesf ../RTL/jtag_tap.sv ../TEST/jtag_pkg.sv ../TOP/jtag_sva.sv ../TOP/jtag_top.sv +incdir+../ENV +incdir+../TEST +incdir+../TOP -l compile.log
```
Compile must end with `Errors: 0`. Then run any test (change the test name):
```
vsim -vopt jtag_top -c -do "run -all; exit" +UVM_TESTNAME=jtag_reset_tc1 -l tc1_reset.log
```

| TC | Test name (`+UVM_TESTNAME=`) | What it checks |
|---|---|---|
| base | `jtag_base_test` | Smoke test: reset, read IDCODE, BYPASS |
| 1 | `jtag_reset_tc1` | TRST_N reset and 5 x TMS=1 reset from every state; IDCODE selected after reset |
| 2 | `jtag_fsm_tc2` | Walk through all 16 states, all 32 state transitions |
| 3 | `jtag_ir_tc3` | Load all 16 opcodes, IR capture value `0001`, which data register is selected |
| 4 | `jtag_idcode_tc4` | IDCODE read after reset and after loading IDCODE, 64-bit scan, repeated reads |
| 5 | `jtag_bypass_tc5` | 1-bit delay through BYPASS, lengths 1–64, unused opcodes act as BYPASS |
| 6 | `jtag_random_tc6` | Random instructions and scans, random TMS / TDI / TRST_N |
| 7 | `jtag_corner_tc7` | Pause/resume, long pause, Exit2→Update, back-to-back scans, 8-bit IR scan, reset during shift |
| 8 | `jtag_regression_tc8` | TC1–TC7 in one simulation → **100 % functional coverage** |

---

## 5. How to read a log file

Each log contains:

1. **Every IR / DR scan checked by the scoreboard**, for example:
   ```
   [JTAG_SB] IR SCAN #1 : length = 4 | TDI in = 0xf | TDO out = 0x1 | expected = 0x1 | new instruction = 1111 (BYPASS) --> MATCH
   [JTAG_SB] DR SCAN #2 : register = IDCODE | length = 32 | TDI in = 0x0 | TDO out = 0x1cafe157 | expected = 0x1cafe157 --> MATCH
   ```
2. **Scoreboard summary** – must end with `RESULT : TEST PASSED`.
3. **Functional coverage** – per coverpoint and `JTAG - Total Coverage`.
4. **UVM report summary** – must show `UVM_ERROR : 0` and `UVM_FATAL : 0`.

If an assertion fails, QuestaSim prints `** Error: A_<NAME> : ...` – there should be **none**.

---

## 6. Merged coverage report (optional)

From the **`SIM`** folder, after compiling (Section 4):
```
vsim -coverage -vopt jtag_top -c -do "coverage save -onexit tc1cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_reset_tc1
vsim -coverage -vopt jtag_top -c -do "coverage save -onexit tc2cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_fsm_tc2
vsim -coverage -vopt jtag_top -c -do "coverage save -onexit tc3cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_ir_tc3
vsim -coverage -vopt jtag_top -c -do "coverage save -onexit tc4cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_idcode_tc4
vsim -coverage -vopt jtag_top -c -do "coverage save -onexit tc5cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_bypass_tc5
vsim -coverage -vopt jtag_top -c -do "coverage save -onexit tc6cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_random_tc6
vsim -coverage -vopt jtag_top -c -do "coverage save -onexit tc7cov.ucdb; run -all; exit" +UVM_TESTNAME=jtag_corner_tc7
vcover merge mergecov.ucdb tc1cov.ucdb tc2cov.ucdb tc3cov.ucdb tc4cov.ucdb tc5cov.ucdb tc6cov.ucdb tc7cov.ucdb
vcover report -details mergecov.ucdb -file coverage_report.txt
vcover report -details -html mergecov.ucdb
```
Open `covhtmlreport/index.html` in a browser. (This step needs a QuestaSim coverage license.
If it is not available, the coverage numbers printed in each log in Section 5 are enough.)

---

## 7. Waveforms (optional)

From the **`SIM`** folder, after compiling:
```
vsim -vopt -voptargs=+acc jtag_top -do run.do +UVM_TESTNAME=jtag_corner_tc7
```
`run.do` adds the JTAG pins (TCK, TRST_N, TMS, TDI, TDO, TDO_EN), the FSM state, the instruction
register, the IDCODE / BYPASS registers and the control signals.

---

## 8. Makefile (optional – Linux or if `make` is installed)

From the **`SIM`** folder:
```
make help          # list of all targets
make run_tc1       # compile + run test case 1 (run_tc2 ... run_tc8 the same way)
make regress       # compile + run all test cases
make run_merge     # all test cases with coverage + merged HTML report
```

---

## 9. Troubleshooting

| Message | Cause | Fix |
|---|---|---|
| `Cannot find path ../RTL/...` or `Failed to open file` | Command not run from the `SIM` folder | `cd` into `SIM` and run again |
| `vsim-7019: Can't locate a C/C++ compiler for 'DPI Export Compilation'` | A self-compiled UVM library is being used | Delete the `work` folder and compile **without** any `+incdir+<uvm path>` or `uvm_pkg.sv`; QuestaSim's built-in UVM is used automatically |
| `Could not find field/method name (record_field_int)` | Mixed UVM versions (custom UVM macros + built-in UVM package) | Same fix as above |
| `Design unit jtag_top not found` | Compile step was skipped or failed | Run `vlib work` and the `vlog` command (Section 4) first, check `Errors: 0` |
| Warning about `-vopt` being deprecated | Newer QuestaSim versions | Harmless – the test still runs |
| Coverage license error in Section 6 | No coverage license | Skip Section 6; coverage is still printed in every log |
