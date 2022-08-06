# cpu_load_store.s:
# -------------------------
# Testing load/store word op (for now)

# Test address (used by unit test)
.equ CONSTANT, 0xcafebabe

        # Load, shift, and store back to next memory word
        li   x10, CONSTANT
        lw   x9, 0(x10)
        slli x9, x9, 1
        sw   x9, 4(x10)

        # Load it back to test register (x31)
        lw   x31, 4(x10)
        addi x1, x0, -1 # Done signal for simulation
STALL:  jal  x2, STALL
        # Add some nop padding
        nop
        nop
        nop
        nop
