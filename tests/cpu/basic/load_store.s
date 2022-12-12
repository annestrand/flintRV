# load_store.s:
# -------------------------
# Testing load/store instructions

# Test immediates (used by unit test)
.equ TEST_ADDR, 0x100
.equ TEST_DATA, 0xdeadbeef
.equ LB_GOLD,   0xffffffef
.equ LH_GOLD,   0xffffbeef
.equ LBU_GOLD,  0x000000ef
.equ LHU_GOLD,  0x0000beef
.equ TEST_DONE, 0xcafebabe

        # Setup
        li   s1, TEST_DATA
        li   s2, LB_GOLD
        li   s3, LH_GOLD
        li   s4, LBU_GOLD
        li   s5, LHU_GOLD
        li   s6, 1
        li   s7, 0

        # Load tests
        li   a0, TEST_ADDR
        lb   a1, 0(a0)
        lh   a2, 0(a0)
        lw   a3, 0(a0)
        lbu  a4, 0(a0)
        lhu  a5, 0(a0)
        bne  a1, s2, FAIL
        addi s6, s6, 1
        bne  a2, s3, FAIL
        addi s6, s6, 1
        bne  a3, s1, FAIL
        addi s6, s6, 1
        bne  a4, s4, FAIL
        addi s6, s6, 1
        bne  a5, s5, FAIL
        # Store tests (Evaluate on simulated memory)
        sb   s1,  4(a0)
        sh   s1,  8(a0)
        sw   s1, 12(a0)
        j    STALL

FAIL:   add  s7, x0, s6
STALL:  ebreak
        j    STALL
        # Add some nop padding
        nop
        nop
        nop
        nop
