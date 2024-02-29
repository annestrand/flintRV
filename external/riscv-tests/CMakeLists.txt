cmake_minimum_required(VERSION 3.12)

project(riscv-tests ASM)

set(CMAKE_MODULE_PATH "${PARENT_DIR}/cmake" ${CMAKE_MODULE_PATH})
include(AsmBuild)

set(RV32I_ABI -march=rv32i -mabi=ilp32)
set(BAREMETAL -nostdlib -nostartfiles)

add_compile_options(
    ${RV32I_ABI}
    ${BAREMETAL}
)

add_link_options(
    ${RV32I_ABI}
    ${BAREMETAL}
    -Wl,--section-start=.text=0x0,--no-relax
)

asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/addi.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/ori.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/beq.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/or.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/slli.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/slt.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/bltu.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/xor.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/sra.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/add.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/jalr.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/lw.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/srai.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/sh.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/lhu.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/bgeu.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/sub.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/xori.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/lh.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/lbu.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/and.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/srli.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/lui.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/bge.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/jal.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/sb.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/sw.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/sll.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/simple.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/j.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/srl.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/auipc.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/slti.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/blt.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/bne.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/lb.S)
asm_build_riscv_tests(${CMAKE_CURRENT_SOURCE_DIR}/andi.S)
