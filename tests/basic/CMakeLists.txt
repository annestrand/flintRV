cmake_minimum_required(VERSION 3.12)

project(basic C)

set(RV32I_ABI -march=rv32i -mabi=ilp32)

add_compile_options(
    ${RV32I_ABI}
)

add_link_options(
    ${RV32I_ABI}
    -Wl,--section-start=.text=0x0 -Wl,-T${PARENT_DIR}/scripts/flintRV.ld
)

include_directories(${PARENT_DIR}/external)

add_executable(functions ${CMAKE_CURRENT_SOURCE_DIR}/functions.c)

add_custom_command(
    TARGET functions POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary functions functions.hex && xxd -i functions.hex functions.inc
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
