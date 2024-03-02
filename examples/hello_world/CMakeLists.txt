cmake_minimum_required(VERSION 3.12)

project(hello_world_example C)

set(RV32I_ABI -march=rv32i -mabi=ilp32)

add_compile_options(
    ${RV32I_ABI}
)

add_link_options(
    ${RV32I_ABI}
    -Wl,--section-start=.text=0x0 -Wl,-T${PARENT_DIR}/scripts/hello_world.ld
)

add_executable(hello_world 
    ${CMAKE_CURRENT_SOURCE_DIR}/main.c
    ${CMAKE_CURRENT_SOURCE_DIR}/syscalls.c
)

add_custom_command(
    TARGET hello_world POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary hello_world hello_world.hex && xxd -i hello_world.hex hello_world.inc
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)