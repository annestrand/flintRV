# Copyright (c) 2022 Austin Annestrand
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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
