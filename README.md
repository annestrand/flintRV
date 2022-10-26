# boredcore

Another RISC-V cpu core design.

## Design 🗺️
- 4-stage in-order pipelined processor
- Aimed to be implemented as a soft-cpu for use in FPGAs

## Dependencies ✅
- GNU Make
- GCC RISC-V compiler/cross-compiler toolchain
- Icarus Verilog (testing)
- Verilator (testing)
- GoogleTest (testing)
- SymbiYosys (testing)
    - Yosys
    - z3
- Python >= 3.6

## Make configs ⚙
Below are a table of Make config variables:
| Variable     | Behavior                   | Usage                                   | Default             |
|:-------------|:---------------------------|:----------------------------------------|:--------------------|
|TC_TRIPLE     |RISCV-GCC toolchain triple  |$ make TC_TRIPLE=riscv64-unknown-elf ... | riscv64-unknown-elf |
|GTEST_BASEDIR |GoogleTest install dir      |$ make GTEST_BASEDIR=/opt/gtest/lib ...  | /usr/local/lib      |
|DOCKER        |Use Docker GCC toolchain    |$ make DOCKER=1 ...                      | 0 (OFF)             |

## Simulator 🖥

To build Verilator simulator:

    $ make sim


## Testing 🧪
Functional Verification:
- `iverilog`    : Unit testing CPU sub-modules
- `Verilator`   : CPU testing

Formal Verification:
- `SymbiYosys`  : Formal verify critical pieces of sub-module logic (TODO)

To build tests:

    $ make tests

CPU test runner:          `build/cpu/Vboredcore`
Submodule test runner(s): `build/sub/<module_name>.out`

## Docker 🐳
RISC-V GCC cross-compiler is needed for building tests and building example firmware. There is a Dockerfile
here to take care of this (easy-mode).

To build and start the container (need to run at least once to ensure container is running):

    $ make docker

Then to build the tests:

    $ make tests DOCKER=ON

## boredsoc
`boredsoc/` directory provides a very basic example SoC using the boredcore soft-cpu.

The CPU is generated using the `scripts/core_gen.py` utility by the `soc` Make recipe (see below).

### Design 🗺️
- CPU specs
    - RV32I ISA
    - No interface protocol applied (i.e. using custom interfacing)
    - Pipelined (4-stages)
    - Static branch prediction (assume not taken)
- SoC specs
    - 2KB Instruction memory (pre-programmed in BRAM, readonly)
    - 2KB Data RAM
    - 1 Output pin (e.g. hello-world LED blink)

### Build Firmware and Generate CPU core for SoC 🛠️
    $ make soc
