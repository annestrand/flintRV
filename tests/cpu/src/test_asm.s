# Nonsensical test program for now
        addi x6, x0, 5
        xori x8, x6, 15
        add  x4, x0, x0
        #add  x0, x0, x0
        add  x5, x0, x0
        addi x5, x0, 10
LOOP:   addi x8, x8, 1
        addi x4, x4, 1
        bne  x4, x5, LOOP
STALL:  jal  x2, STALL