# rISA
A simple RISC-V ISA Simulator.

```
 ________  ___  ________  ________
|\   __  \|\  \|\   ____\|\   __  \
\ \  \|\  \ \  \ \  \___|\ \  \|\  \
 \ \   _  _\ \  \ \_____  \ \   __  \
  \ \  \\  \\ \  \|____|\  \ \  \ \  \
   \ \__\\ _\\ \__\____\_\  \ \__\ \__\
    \|__|\|__|\|__|\_________\|__|\|__| - RISC-V (RV32I) ISA simulator
                  \|_________|

[rISA] [/home/wsl/src/rISA/src/risa.c:165] [INFO]: Interrupt period set to: 500 cycles.
[rISA] [/home/wsl/src/rISA/src/risa.c:166] [INFO]: Virtual memory size set to: 0.031250 MB.
[rISA] [/home/wsl/src/rISA/src/risa.c:180] [INFO]: Running simulator...
============================================================================================
Hello World in rISA!
============================================================================================
[rISA] [/home/wsl/src/rISA/src/risa.c:53] [INFO]: Simulation stopping, time elapsed: 0.000122 seconds.
```

## Project features
- Functional simulation of RV32I
- Cross platform (Windows, macOS, Linux)
- GDB mode to run simulator as a gdbserver
    - Feature is currently experimental
- Optional runtime loading of user-defined handlers via shared library (i.e. `dlopen`/`LoadLibrary`)
    - MMIO handler
    - Environment handler (i.e. FENCE, ECALL and EBREAK)
    - Interrupt handler

## rISA handler functions
rISA allows for the user to define their own handler functions for dealing with either
Memory-Mapped I/O (MMIO), Environment Calls (Env), Interrupts (Int), Initialization
(Init), and the Exit handler (Exit).
```c
void risaMmioHandler(rv32iHart *cpu);
void risaIntHandler(rv32iHart *cpu);
void risaEnvHandler(rv32iHart *cpu);
void risaInitHandler(rv32iHart *cpu);
void risaExitHandler(rv32iHart *cpu);
```
The user can define their own handler functions separately, compile them to a dynamic library, then pass the
dynamic library as a command-line argument to rISA.

This repo comes with an example handler
(in the `examples/risa_handler` folder) that just indicates/prints that it was called.

The cpu simulation object also contains an opaque user-data pointer:
```c
void *handlerData;
```

The user-provided handler function(s) library will be able to utilize this data pointer to store
runtime information to the cpu object via this pointer (e.g. MMIO address ranges, trace info, etcetera).
