#ifndef RISCV_TEST_H
#define RISCV_TEST_H

#ifndef TEST_FUNC_NAME
#define TEST_FUNC_NAME mytest
#define TEST_FUNC_TXT "mytest"
#define TEST_FUNC_RET mytest_ret
#endif

#define RVTEST_RV32U
#define TESTNUM x28

#define RVTEST_CODE_BEGIN           \
    .section .text;                 \
    .global _start;                 \
    _start: nop;                    \
    .global TEST_FUNC_NAME;         \
    .global TEST_FUNC_RET;

#define RVTEST_PASS                 \
    addi    a1,zero,'O';            \
    addi    a2,zero,'K';            \
    addi    a3,zero,  0;            \
    ebreak;

#define RVTEST_FAIL                 \
    addi    a1,zero,'E';            \
    addi    a2,zero,'R';            \
    addi    a3,zero,'R';            \
    ebreak;

#define RVTEST_CODE_END
#define RVTEST_DATA_BEGIN .balign 4;
#define RVTEST_DATA_END

#endif
