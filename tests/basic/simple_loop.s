# Copyright (c) 2023 - present, Austin Annestrand
# Licensed under the MIT License (see LICENSE file).

# simple_loop.s:
# -------------------------
#  int j = 0;
#  for (int i=0; i<10; ++i) {
#    j += i;
#  }
#  // Expected result: j == 45

.section .text;
.global _start;
_start:

        li  s3, 0           # i = 0
        li  s2, 0           # j = 0
        li  s4, 10          # loop-range
LOOP:   add  s2, s3, s2     # j += i
        addi s3, s3, 1      # ++i
        bne  s3, s4, LOOP   # i<10
        ebreak
STALL:  j  STALL
        # Add some nop padding
        nop
        nop
        nop
        nop
