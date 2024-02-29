cmake_minimum_required(VERSION 3.12)

project(drop32soc ASM)

find_package (Python COMPONENTS Interpreter)
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
)

asm_build_verilog(${CMAKE_CURRENT_SOURCE_DIR}/firmware.s)

add_custom_command(
    TARGET firmware POST_BUILD
    COMMAND ${Python_EXECUTABLE} ${PARENT_DIR}/scripts/drop32soc_gen.py > ${CMAKE_BINARY_DIR}/drop32soc_generated.v
)
