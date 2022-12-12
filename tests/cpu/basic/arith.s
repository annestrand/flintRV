# --- Arith tests ---
#     (Fails if x30 is non-zero)
#
# Init Immediate values:            [ -371, 19, 23 ]
# Init regfile values (x0 - x13):   [ 0, 439, -371, 68, 810, 230162432, 1182793728, 0, 511, 0, 4294967295, 23, 19 ]
#
# (Init regfile values are initialized in C++ test src)

        addi  x30, x30, 1
        addi  x13, x1, -371
        bne   x13, x3, FAIL
        addi  x30, x30, 1
        add   x13, x1, x2
        bne   x13, x3, FAIL
        addi  x30, x30, 1
        sub   x13, x1, x2
        bne   x13, x4, FAIL
        addi  x30, x30, 1
        slli  x13, x1, 19
        bne   x13, x5, FAIL
        addi  x30, x30, 1
        sll   x13, x1, x12
        bne   x13, x5, FAIL
        addi  x30, x30, 1
        slli  x13, x2, 23
        bne   x13, x6, FAIL
        addi  x30, x30, 1
        sll   x13, x2, x11
        bne   x13, x6, FAIL
        addi  x30, x30, 1
        srli  x13, x1, 19
        bne   x13, x7, FAIL
        addi  x30, x30, 1
        srl   x13, x1, x12
        bne   x13, x7, FAIL
        addi  x30, x30, 1
        srli  x13, x2, 23
        bne   x13, x8, FAIL
        addi  x30, x30, 1
        srl   x13, x2, x11
        bne   x13, x8, FAIL
        addi  x30, x30, 1
        srai  x13, x1, 19
        bne   x13, x9, FAIL
        addi  x30, x30, 1
        sra   x13, x1, x12
        bne   x13, x9, FAIL
        addi  x30, x30, 1
        srai  x13, x2, 23
        bne   x13, x10, FAIL
        addi  x30, x30, 1
        sra   x13, x2, x11
        bne   x13, x10, FAIL
        addi  x30, x30, 1
        jal   x29, STALL

FAIL:   add  x31, x0, x30
STALL:  ebreak
        jal  x0, STALL
        # Add some NOP padding
        nop
        nop
        nop
        nop
