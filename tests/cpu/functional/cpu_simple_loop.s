# simple_loop.s:
# -------------------------
#  int j = 0;
#  for (int i=0; i<10; ++i) {
#    j += i;
#  }
#  // Expected result: j == 45
#
        li  x4, 0           # i = 0
        li  x8, 0           # j = 0
        li  x5, 10          # loop-range
LOOP:   add  x8, x4, x8     # j += i
        addi x4, x4, 1      # ++i
        bne  x4, x5, LOOP   # i<10
        addi x1, x0, -1     # Done signal for simulation
STALL:  jal  x2, STALL
        # Add some nop padding
        nop
        nop
        nop
        nop
