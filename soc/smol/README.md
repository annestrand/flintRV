# smol SoC 🤏

A simple example SoC using the boredcore soft-cpu.
The CPU `g_core.v` is pre-generated using the `scripts/core_gen.py` utility.

## Design 🗺️
- CPU specs
    - RV32I ISA
    - No interface protocol applied (i.e. using custom interfacing)
    - Pipelined (4-stages)
    - Static branch prediction (assume not taken)
- SoC specs
    - 2KB Instruction memory (pre-programmed in BRAM, readonly)
    - 2KB Data RAM
    - 1 Output pin (e.g. hello-world LED blink)

## Build Firmware 🛠️
    $ make smol