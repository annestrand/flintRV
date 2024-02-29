cmake_minimum_required(VERSION 3.12)

project(algorithms C)

set(RV32I_ABI -march=rv32i -mabi=ilp32)

add_compile_options(
    ${RV32I_ABI}
)

add_link_options(
    ${RV32I_ABI}
    -Wl,--section-start=.text=0x0 -Wl,-T${PARENT_DIR}/scripts/drop32.ld
)

add_executable(binsearch ${CMAKE_CURRENT_SOURCE_DIR}/binsearch.c)
add_executable(fibonacci ${CMAKE_CURRENT_SOURCE_DIR}/fibonacci.c)
add_executable(mergesort ${CMAKE_CURRENT_SOURCE_DIR}/mergesort.c)

add_custom_command(
    TARGET binsearch POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary binsearch binsearch.hex && xxd -i binsearch.hex binsearch.inc
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
add_custom_command(
    TARGET fibonacci POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary fibonacci fibonacci.hex && xxd -i fibonacci.hex fibonacci.inc
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
add_custom_command(
    TARGET mergesort POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary mergesort mergesort.hex && xxd -i mergesort.hex mergesort.inc
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
