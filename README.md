# boredcore
Codename working private repo for pineapplecore 🍍

⚠ Repo still subject to change (WIP) ⚠

## Design
- 4-stage in-order pipelined processor
- Harvard architecture
- Configurable RISC-V extensions (RV32I)
    - (TODO): which extensions?

## Dependencies
- GNU Make
- Icarus Verilog (optional - for testing)
- Python >= 3.7 (optional - for testing)

## Testing 🧪
Functional Verification:
- `iverilog`    : Unit testing sub-modules (maaaaybe TB for the final core to use VPI to interact with CPU)
- `Verilator`   : Full-design run on RISC-V programs/benchmarks

Formal Verification:
- `SymbiYosys`  : Formal verify critical pieces of sub-module logic

## Docker 🐳
RISC-V GCC cross-compiler is needed for running tests and building example firmware. There is a Dockerfile
here to take care of this (easy-mode).

First time setup:

    $ docker build -t riscv-gnu-toolchain .
    $ docker create -it -v $(pwd):/src --name pineapplecore-toolchain riscv-gnu-toolchain

Then start/stop container whenever needed:

    $ docker <start|stop> pineapplecore-toolchain

Once container is "started"/running, run make by also specifiying `DOCKER=ON` - Example:

    $ make tests DOCKER=ON

