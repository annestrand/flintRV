# Copyright (c) 2023 - present, Austin Annestrand
# Licensed under the MIT License (see LICENSE file).

# firmware.s:
# -------------------------
# Test program to blink an LED on drop32soc

.equ LED_BASE, 0x00003000

        li  x20, LED_BASE
        li  x4, 0           # i = 0
        li  x8, 0           # j = 0
        li  x9, 0           # LED_val = 0
        li  x5, 500000      # loop-range
LOOP:   add  x8, x4, x8     # j += i
        addi x4, x4, 1      # ++i
        bne  x4, x5, LOOP   # i<(loop-range)
        xori x9, x9, 1      # Toggle LED
        sb   x9, 0(x20)     # Update LED value
        li   x4, 0          # i = 0
        j LOOP
        # Add some nop padding
        nop
        nop
        nop
        nop
