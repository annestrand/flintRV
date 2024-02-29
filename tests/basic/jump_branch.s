# Copyright (c) 2023 - present, Austin Annestrand
# Licensed under the MIT License (see LICENSE file).

# --- Jump/Branch tests ---
#   (Fails if s1 is non-zero)

.section .text;
.global _start;
_start:

    li    s3, 1
    li    s1, 0
    j     L0
    addi  s1, s1, 1
L0: jalr  zero, zero, 24    # Jump to "beq" below
    addi  s1, s1, 1
    beq   zero, zero, L1
    addi  s1, s1, 1
L1: bne   s1, s3, L2
    addi  s1, s1, 1
L2: blt   zero, s3, L3
    addi  s1, s1, 1
L3: bge   s3, zero, L4
    addi  s1, s1, 1
L4: bltu  zero, s3, L5
    addi  s1, s1, 1
L5: bgeu  s3, zero, STALL
    addi  s1, s1, 1

STALL:  ebreak
        # Add some NOP padding
        nop
        nop
        nop
        nop
        j STALL
