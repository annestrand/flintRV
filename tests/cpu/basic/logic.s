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