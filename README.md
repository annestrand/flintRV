# flintRV

<img src="https://devbored.io/images/flintRV_logo.png" width="20%" align="right"/>

- RV32I ISA
- 4-stage in-order pipelined processor
- Simple RISC-V soft-core CPU aimed for use in FPGAs

# Prerequisites ✅
- Python >= 3.6
- CMake >= 3.12 (**optional**)
- C++14 compiler (or greater) (**optional**)
- Verilator >= 4.028 (**optional**)
- GoogleTest (**optional**)
- GCC RISC-V compiler/cross-compiler toolchain (**optional**)

# Pre-build ⚒️
This repo uses git submodules - make sure to pull those first:

    git submodule update --init --recursive

# Generate flintRV core
There is a convenience script to generate a singular core/CPU RTL file to stdout:

    python3 ./scripts/core_gen.py [opts]

Use `-h` to list available options.

# Generate flintRV SoC
`flintRVsoc/` directory provides a very basic example SoC using the flintRV soft-cpu, to generate just the SoC: 

    python3 ./scripts/flintRVsoc_gen.py

To build Firmware as well as generate SoC:

    cmake -Bbuild -DBUILD_SOC=ON
    cmake --build build

Output SoC Files: `<OUTPUT_DIR>/<RISCV_TOOLCHAIN_TRIPLE>/flintRVsoc`

- CPU specs
    - RV32I ISA
    - No interface protocol applied (i.e. using custom interfacing)
    - Pipelined (4-stages)
    - Static branch prediction (assume not taken)
- SoC specs
    - 1KB Instruction memory (pre-programmed in BRAM, readonly)
    - 1KB Data RAM
    - 1 Output pin (e.g. hello-world LED blink)

# Build rISA and flintRV simulators 🖥

    cmake -Bbuild
    cmake --build build

- [rISA Documentation](./sim/risa/README.md)
- [flintRV Documentation](./sim/flintRV/README.md)

# Build Tests 🧪
Building tests require the above `optional` prerequisites.

To build tests:

    cmake -Bbuild -DBUILD_TESTS=ON
    cmake --build build

Test runner: `<OUTPUT_DIR>/flintRV_tests`
