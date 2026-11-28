# How to Run – JTAG TAP Controller UVM Verification

This guide explains how to compile and run the project in QuestaSim and how to check the results.
The main check is **one command** (Section 3) and takes about 1–2 minutes.

\---

## 1\. Requirements

|Item|Details|
|-|-|
|Simulator|Siemens QuestaSim (tested on **QuestaSim 10.7c, Windows**). QuestaSim 10.6 or newer should work.|
|UVM library|The **UVM library built into QuestaSim** is used. Nothing to download or install.|
|C compiler|**Not needed.**|
|`make`|**Not needed** (optional, Section 8).|

> Do \*\*not\*\* compile your own copy of UVM or pass `+incdir+<uvm path>`. The project uses QuestaSim's built-in UVM, the same way as the course lab projects.

\---

## 2\. Get the project

**Option A – Git**

```
git clone https://github.com/aadityasinghchouhan/UVM\_Verification\_of\_JTAG\_TAP\_Controller.git
```

**Option B – ZIP**
On the GitHub page click **Code → Download ZIP** and unzip it.

Folder structure:

```
UVM\_Verification\_of\_JTAG\_TAP\_Controller/
├── RTL/       jtag\_tap.sv                         (design)
├── ENV/       interface, agent, driver, monitor, scoreboard, coverage, env
├── TEST/      jtag\_pkg.sv, base test, test cases TC1–TC8 and their sequences
├── TOP/       jtag\_top.sv (testbench top), jtag\_sva.sv (assertions + cover properties)
├── BUGS/      jtag\_tap\_bug1.sv ... jtag\_tap\_bug7.sv (bug-injection copies of the RTL)
├── SIM/       run\_all.do, run\_cov.do, run\_bugs.do, run\_seeds.do, Makefile, run.do
│                                                  <-- ALL COMMANDS ARE RUN FROM HERE
├── RESULTS/   regression/, coverage/, bug\_injection/, seeds/  (written by the scripts)
├── README.md
└── HOW\_TO\_RUN.md
```

> \*\*Important:\*\* every command below must be run from inside the \*\*`SIM`\*\* folder, because the scripts use relative paths such as `../RTL/jtag\_tap.sv`.

\---

## 3\. Quick run – all tests with ONE command (recommended)

### Option A – from a terminal (Windows PowerShell / Command Prompt, or Linux shell)

```
cd <path-to-project>/SIM
vsim -c -do run\_all.do
```

### Option B – from the QuestaSim GUI

1. Open QuestaSim.
2. **File → Change Directory…** and select the project's **`SIM`** folder.
3. In the **Transcript** window type:

```
   do run\_all.do
   ```

### Expected result

```
======================== JTAG TAP REGRESSION SUMMARY ========================
  TEST                    RESULT        UVM\_ERROR       FUNCTIONAL COVERAGE
  jtag\_base\_test          TEST PASSED   0               ... %
  jtag\_reset\_tc1          TEST PASSED   0               ... %
  ...
  jtag\_regression\_tc8     TEST PASSED   0               100.00 %
=============================================================================
  OVERALL : ALL 9 TESTS PASSED
=============================================================================
```

* Every test must show **TEST PASSED** and **UVM\_ERROR 0**.
* **`jtag\_regression\_tc8` shows 100.00 % functional coverage.** Single tests show lower
coverage on their own because each one targets one feature.
* Logs: `RESULTS/regression/<test name>.log`. Summary: `RESULTS/regression/regression\_summary.txt`.

\---

## 4\. Other scripts (optional)

All run from the **`SIM`** folder, the same way as Section 3 (`vsim -c -do <script>` in a
terminal, or `do <script>` in the GUI Transcript).

|Script|What it does|Time|Result file|
|-|-|-|-|
|`run\_cov.do`|Runs TC1–TC7 with coverage, merges them, writes text + HTML reports. Code coverage is collected on the design only. **Needs a coverage license.**|\~2 min|`RESULTS/coverage/coverage\_summary.txt`, `coverage\_report.txt`, `covhtmlreport/index.html`|
|`run\_bugs.do`|Bug-injection experiment: compiles each of the 7 buggy copies in `BUGS/` and runs the full regression on it. Every bug must be **DETECTED**.|\~5 min|`RESULTS/bug\_injection/bug\_summary.txt`|
|`run\_seeds.do`|Runs the random test (TC6) with 10 different seeds. Every seed must pass.|\~2 min|`RESULTS/seeds/seeds\_summary.txt`|

**Expected `run\_bugs.do` result:** a table with 7 rows, each ending in `DETECTED`, and
`DETECTED : 7 of 7 bugs`. These runs are *supposed* to show errors – that is how the
testbench proves it catches the bug. `run\_bugs.do` deletes the `work` library at the end
(it held a buggy design), so run `run\_all.do` again before running single tests.

\---

## 5\. Run one test at a time

From the **`SIM`** folder:

```
vlib work
vlog -sv +cover=bcesft ../RTL/jtag\_tap.sv
vlog -sv ../TEST/jtag\_pkg.sv ../TOP/jtag\_sva.sv ../TOP/jtag\_top.sv +incdir+../ENV +incdir+../TEST +incdir+../TOP
```

Both compile steps must end with `Errors: 0`. Then run a test (change the test name as needed):

```
vsim -vopt jtag\_top -c -do "run -all; exit" +UVM\_TESTNAME=jtag\_reset\_tc1 -l tc1\_reset.log
```

|TC|Test name (`+UVM\_TESTNAME=`)|What it checks|
|-|-|-|
|base|`jtag\_base\_test`|Smoke test: reset, read IDCODE, BYPASS|
|1|`jtag\_reset\_tc1`|TRST\_N reset and 5 x TMS=1 reset from every state; IDCODE selected after reset|
|2|`jtag\_fsm\_tc2`|All 16 states and all 32 state transitions|
|3|`jtag\_ir\_tc3`|Load all 16 opcodes, IR capture value `0001`, selected data register|
|4|`jtag\_idcode\_tc4`|IDCODE after reset and after loading IDCODE, 64-bit scan, repeated reads|
|5|`jtag\_bypass\_tc5`|1-bit delay through BYPASS, lengths 1–64, unused opcodes act as BYPASS|
|6|`jtag\_random\_tc6`|Random instructions and scans, random TMS / TDI / TRST\_N|
|7|`jtag\_corner\_tc7`|Pause/resume, long pause, Exit2→Update, back-to-back scans, 8-bit IR scan, reset during shift|
|8|`jtag\_regression\_tc8`|TC1–TC7 in one simulation → **100 % functional coverage**|

\---

## 6\. How to read a log file

Each log contains:

1. **Every IR / DR scan checked by the scoreboard**, for example:

```
   \[JTAG\_SB] DR SCAN #2 : register = IDCODE | length = 32 | TDI in = 0x0 | TDO out = 0x1cafe157 | expected = 0x1cafe157 --> MATCH
   ```

2. **Scoreboard summary** – must end with `RESULT : TEST PASSED`.
3. **Functional coverage** – per coverpoint and `JTAG - Total Coverage`.
4. **Assertion cover summary** – how many times each checked situation happened (all should be above 0 in TC8).
5. **UVM report summary** – must show `UVM\_ERROR : 0` and `UVM\_FATAL : 0`.

If an assertion fails, QuestaSim prints `\*\* Error: A\_<NAME> : ...` – in a normal run there should be **none**.

\---

## 

