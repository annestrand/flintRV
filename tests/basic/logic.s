# Copyright (c) 2023 Austin Annestrand
# Licensed under the MIT License (see LICENSE file).

# --- Logic tests ---
#     (Fails if x30 is non-zero)
#
# Init Immediate values:            [ 391 ]
# Init regfile values (x0 - x9):    [ 0, 834, 391, 258, 967, 709, 391, 258, 967, 709 ]
#
# (Init regfile values are initialized in C++ test src)

        addi  x30, x30, 1
        andi  x6, x1, 391
        bne   x6, x3, FAIL
        addi  x30, x30, 1
        and   x6, x1, x2
        bne   x6, x3, FAIL
        addi  x30, x30, 1
        ori   x6, x1, 391
        bne   x6, x4, FAIL
        addi  x30, x30, 1
        or    x6, x1, x2
        bne   x6, x4, FAIL
        addi  x30, x30, 1
        xori  x6, x1, 391
        bne   x6, x5, FAIL
        addi  x30, x30, 1
        xor   x6, x1, x2
        bne   x6, x5, FAIL
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
