# load_store.s:
# -------------------------
# Testing load/store instructions

# Test immediates (used by unit test)
.equ TEST_ADDR, 0x1000
.equ TEST_DATA, 0xdeadbeef
.equ LB_GOLD,   0xffffffef
.equ LH_GOLD,   0xffffbeef
.equ LBU_GOLD,  0x000000ef
.equ LHU_GOLD,  0x0000beef

        # Setup
        li   x20, TEST_DATA
        li   x21, LB_GOLD
        li   x22, LH_GOLD
        li   x23, LBU_GOLD
        li   x24, LHU_GOLD
        li   x30, 1
        li   x31, 0

        # Load tests
        li   x10, TEST_ADDR
        lb   x11, 0(x10)
        lh   x12, 0(x10)
        lw   x13, 0(x10)
        lbu  x14, 0(x10)
        lhu  x15, 0(x10)
        bne  x11, x21, FAIL
        addi x30, x30, 1
        bne  x12, x22, FAIL
        addi x30, x30, 1
        bne  x13, x20, FAIL
        addi x30, x30, 1
        bne  x14, x23, FAIL
        addi x30, x30, 1
        bne  x15, x24, FAIL
        # Store tests (Evaluate on simulated memory)
        sb   x20,  4(x10)
        sh   x20,  8(x10)
        sw   x20, 12(x10)
        j    STALL

FAIL:   addi x1, x0, -1 # Done signal for simulation
        add  x31, x0, x30
STALL:  addi x1, x0, -1 # Done signal for simulation
        jal  x2, STALL
        # Add some nop padding
        nop
        nop
        nop
        nop
