cmake_minimum_required(VERSION 3.12)

project(basic ASM)

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
    -Wl,--section-start=.text=0x0
)

asm_build(${CMAKE_CURRENT_SOURCE_DIR}/arith.s)
asm_build(${CMAKE_CURRENT_SOURCE_DIR}/jump_branch.s)
asm_build(${CMAKE_CURRENT_SOURCE_DIR}/load_store.s)
asm_build(${CMAKE_CURRENT_SOURCE_DIR}/logic.s)
asm_build(${CMAKE_CURRENT_SOURCE_DIR}/simple_loop.s)
