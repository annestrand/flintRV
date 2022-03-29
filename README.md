# pineapplecore 🍍
Another RISCV core.

⚠ [Work In Progress]: Repo still subject to many changes ⚠

## Design 🗺
- 4-stage in-order pipelined processor
- Harvard architecture
- Configurable RISC-V extensions (RV32I)
    - (TODO): Extensions later?

## Dependencies ✅
- GNU Make
- GCC RISC-V compiler/cross-compiler toolcahin  (optional - for testing)
- Icarus Verilog                                (optional - for testing)
- Python >= 3.6                                 (optional - for testing)

## Make configs ⚙
Below are a table of Make config variables:
| Variable | Behavior                   | Usage                                   | Default             |
|:---------|:---------------------------|:----------------------------------------|:--------------------|
|VCD       |Dump VCD file               |$ make VCD=1 ...                         | 0 (OFF)             |
|TC_TRIPLE |RISCV-GCC toolcahin triple  |$ make TC_TRIPLE=riscv64-unknown-elf ... | riscv64-unknown-elf |
|DOCKER    |Use Docker GCC toolchain    |$ make DOCKER=1 ...                      | 0 (OFF)             |

## Testing 🧪
Functional Verification:
- `iverilog`    : Unit testing sub-modules (maaaaybe TB for the final core to use VPI to interact with CPU)
- `Verilator`   : Full-design run on RISC-V programs/benchmarks (TODO)

Formal Verification:
- `SymbiYosys`  : Formal verify critical pieces of sub-module logic (TODO)

To build the functional tests:

    $ make tests

Build and run all tests:

    $ make runtests

Each case outputs to `build/` directory.

## Docker 🐳
RISC-V GCC cross-compiler is needed for running tests and building example firmware. There is a Dockerfile
here to take care of this (easy-mode).

First time setup:

    $ docker build -t riscv-gnu-toolchain .
    $ docker create -it -v $(pwd):/src --name pineapplecore-toolchain riscv-gnu-toolchain

Then start/stop container whenever needed:

    $ docker <start|stop> pineapplecore-toolchain

Once container is "started"/running, run make by also specifiying `DOCKER=ON`:

    $ make tests DOCKER=ON
