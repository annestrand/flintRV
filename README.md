# boredcore
Codename working private repo for pineapplecore 🍍

## Design
- 4-stage in-order pipelined processor
- Harvard architecture
- Configurable RISC-V extensions (RV32I)
    - (TODO): which extensions?

## Testing 🧪
Functional Verification:
- `iverilog`    : Unit testing sub-modules (maaaaybe TB for the final core to use VPI to interact with CPU)
- `Verilator`   : Full-design run on RISC-V programs/benchmarks

Formal Verification:
- `SymbiYosys`  : Formal verify critical pieces of sub-module logic