# simple_loop.s:
# -------------------------
#  int j = 0;
#  for (int i=0; i<10; ++i) {
#    j += i;
#  }
#  // Expected result: j == 45
#
        add  x4, x0, x0 # = i
        add  x5, x0, x0 # = val(10)
        add  x8, x0, x0 # = j
        addi x5, x0, 10
LOOP:   add  x8, x4, x8
        addi x4, x4, 1
        bne  x4, x5, LOOP
        addi x1, x0, -1 # Done signal for simulation
STALL:  jal  x2, STALL
        # Add some nop padding
        add  x0, x0, x0
        add  x0, x0, x0
        add  x0, x0, x0
        add  x0, x0, x0
