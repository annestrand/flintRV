# Changelog

## v0.2 (3/1/2023)

#### General Notes: 📝

Second release - mainly tooling, build-flow, and testing improvement.
Minor RTL tweaks on EXEC stage for modest gain.

Some TODO areas:

- Further EXEC stage latency reduction
- Look into adding CSR's and exception handling (trap handler)
- Look into adding Wishbone interfacing

#### Enhancements: ✨

- Moved all testing to Verilator (singular test runner)
- `make soc` now uses soc script to bundle all srcs to single verilog file
- Reduced pipeline latency at EXEC stage
    - Move jmp/bra resolution to MEM, tweak SLT/SLTU
    - From Fmax of ~15 MHz to **~20 MHz** (using yosys+nextpnr on ice40 up5k FPGA)
- Improved build flow
    - Building Verilated pieces individually now
- Instruction fetch update now works with either BRAM based I$ or LUT based I$
- Simplified RTL srcs
    - Hazard logic
    - ALU logic

#### Bug Fixes: 🪲

- Fixed VCD dumping when running tests
- Removed GoogleTest includes on irrelevant srcs

## v0.1 (12/30/2022)

#### General Notes: 📝

- 1st Release! 🎉
- Namechange: `boredcore` -> `drop32`
- Core RV32I ISA (minus exception handling) implemented and tested
- Updated documentation for how to build tests and simulator
- 100% passing tests:
    - Unit
    - Basic
    - Functional
    - Algorithms

#### Enhancements: ✨

- N/A (1st release)

#### Bug Fixes: 🪲

- N/A (1st release)
