# flintRV Simulator

A cycle-accurate Verilated C++ flintRV RTL simulator.

The C++ code here serves as the wrapper around the Verilated module.

```
$ flintRV ./build/riscv64-unknown-elf/basic/simple_loop.hex --tracing
flintRV - Verilator based flintRV simulator
[INFO][main.cc:85]: Simulation timeout value: 2147483647 cycles.
[INFO][main.cc:87]: Memory size set to: 0.031250 MB.
[INFO][main.cc:91]: Running simulator...
===[ OUTPUT ]===================================================================================================

       0:   0x0badc0de   CPU Reset!                    
       0:   0x00000993   addi s3, zero, 0              
       4:   0x00000913   addi s2, zero, 0              
       8:   0x00a00a13   addi s4, zero, 10             
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
      20:   0x00000013   addi zero, zero, 0            
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
      20:   0x00000013   addi zero, zero, 0            
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
      20:   0x00000013   addi zero, zero, 0            
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
      20:   0x00000013   addi zero, zero, 0            
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
      20:   0x00000013   addi zero, zero, 0            
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
      20:   0x00000013   addi zero, zero, 0            
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
      20:   0x00000013   addi zero, zero, 0            
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
      20:   0x00000013   addi zero, zero, 0            
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
      20:   0x00000013   addi zero, zero, 0            
       c:   0x01298933   add s2, s3, s2                
      10:   0x00198993   addi s3, s3, 1                
      14:   0xff499ce3   bne s3, s4, -8                
      18:   0x00100073   ebreak                        
      1c:   0x0000006f   jal zero, 0                   
================================================================================================================
[INFO][main.cc:127]: Simulation stopping, time elapsed: 0.000394 seconds.
```

## Simulator guide ❓

### Program Input 💾
`flintRV` requires a HEX binary/file of the RISC-V program that you want to run.

One can use `objcopy` to obtain raw HEX of program, for example:
```
$ riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 main.c -o myTest
$ riscv64-unknown-elf-objcopy -O binary myTest myTest.hex
```

Standard usage of `flintRV`:
```
[Usage]: flintRV [OPTIONS] <program_binary>.hex
```

`flintRV` also can take options - these options can be viewed by passing the `-h`/`--help` flag.

### Simulation finish cases 🔚
Besides error cases, the simulator ends if any of the following is true:

- Simulator cycle value reaches timeout value
- Simulator encounters an ebreak instruction
