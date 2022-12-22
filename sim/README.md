# Simulator
Directory contains the Verilator-based boredcore simualtor: `Vboredcore`.

```
$ ./build/Vboredcore ./build/tests/load_store.hex -d 2
[INFO ]:[main.cc:73] - Memory size set to: [ 0.031250 MB ].
[INFO ]:[main.cc:74] - Simulation timeout value:  [ 1000 ].
[INFO ]:[main.cc:78] - Starting simulation...

===[ OUTPUT ]===================================================================================================
       0:   0x0badc0de   CPU Reset!            STALL:[----]  FLUSH:[----]  STATUS:[--R----]  CYCLE:[0]
       0:   0xdeadc4b7   lui s1, 912092        STALL:[x---]  FLUSH:[xxxx]  STATUS:[IM-----]  CYCLE:[1]
       4:   0xeef48493   addi s1, s1, -273     STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[2]
       8:   0xfef00913   addi s2, zero, -17    STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[3]
       c:   0xffffc9b7   lui s3, 1048572       STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[4]
      10:   0xeef98993   addi s3, s3, -273     STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[5]
      14:   0x0ef00a13   addi s4, zero, 239    STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[6]
      18:   0x0000cab7   lui s5, 12            STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[7]
      1c:   0xeefa8a93   addi s5, s5, -273     STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[8]
      20:   0x00100b13   addi s6, zero, 1      STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[9]
      24:   0x00000b93   addi s7, zero, 0      STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[10]
      28:   0x10000513   addi a0, zero, 256    STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[11]
      2c:   0x00050583   lb a1, 0(a0)          STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[12]
      30:   0x00051603   lh a2, 0(a0)          STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[13]
      34:   0x00052683   lw a3, 0(a0)          STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[14]
      38:   0x00054703   lbu a4, 0(a0)         STALL:[----]  FLUSH:[----]  STATUS:[IM---L-]  CYCLE:[15]
      3c:   0x00055783   lhu a5, 0(a0)         STALL:[----]  FLUSH:[----]  STATUS:[IM---L-]  CYCLE:[16]
      40:   0x03259a63   bne a1, s2, 52        STALL:[----]  FLUSH:[----]  STATUS:[IM---L-]  CYCLE:[17]
      44:   0x001b0b13   addi s6, s6, 1        STALL:[----]  FLUSH:[----]  STATUS:[IM---L-]  CYCLE:[18]
      48:   0x03361663   bne a2, s3, 44        STALL:[----]  FLUSH:[xx--]  STATUS:[IM-B-L-]  CYCLE:[19]
      74:   0x01600bb3   add s7, zero, s6      STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[20]
      78:   0x00100073   ebreak                STALL:[----]  FLUSH:[----]  STATUS:[IM-----]  CYCLE:[21]
================================================================================================================

[INFO ]:[main.cc:96] - Simulation done.
```

## Simulator guide ❓
`Vboredcore` requires a HEX binary/file of the RISC-V program that you want to run.

One can use `objcopy` to obtain raw HEX of program, for example:
```
$ riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 main.c -o myTest
$ riscv64-unknown-elf-objcopy -O binary myTest myTest.hex
```

`Vboredcore` also can take options - these options can be viewed via the `-h` flag.

The simulator ends if any of the following is true:

- Simulator cycle value reaches timeout value
- Simulator encounters an ebreak instruction
