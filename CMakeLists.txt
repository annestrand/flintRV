cmake_minimum_required(VERSION 3.12)

project(drop32)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})

# User adjustable vars/options
# ---------------------------------------------------------------------------------------------------------------------
set(RISCV_TOOLCHAIN_TRIPLE "riscv64-unknown-elf" CACHE STRING "RISC-V cross-compiler GCC triplet prefix value")
set(EXTERN_PROJECT_GENERATOR "Ninja" CACHE STRING "Generator for external projects (i.e. riscv cross compilation)")
# ---------------------------------------------------------------------------------------------------------------------
option(GDBLOG OFF)
option(BUILD_SOC OFF)
option(BUILD_TESTS OFF)
option(BUILD_HELLO_WORLD OFF)
# ---------------------------------------------------------------------------------------------------------------------

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})
include(AddMultiTargetComponent)

# Generate C/C++ header of types.vh
# TODO: Make this routine a python script for portability
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/types.h
    COMMAND sed "'s/`/#/g'" ${CMAKE_SOURCE_DIR}/rtl/types.vh |
            sed "\"s/[0-9]*'/0/g\"" |
            awk "'!/{/'" |
            awk "'!/x\\[/'" >
            ${CMAKE_BINARY_DIR}/types.h
    DEPENDS ${CMAKE_SOURCE_DIR}/rtl/types.vh
)
add_custom_target(typesVh ALL DEPENDS ${CMAKE_BINARY_DIR}/types.h)

# C-based functional RV32I simulator
add_executable(risa
    ${CMAKE_SOURCE_DIR}/sim/risa/main.c
    ${CMAKE_SOURCE_DIR}/sim/risa/risa.c
    ${CMAKE_SOURCE_DIR}/sim/risa/socket.c
    ${CMAKE_SOURCE_DIR}/sim/risa/handlers.c
    ${CMAKE_SOURCE_DIR}/sim/risa/gdbserver.c
)
target_include_directories(risa PUBLIC
    ${CMAKE_SOURCE_DIR}/sim/risa
    ${CMAKE_SOURCE_DIR}/external/minigdbstub
    ${CMAKE_SOURCE_DIR}/external/miniargparse
)
set_property(TARGET risa PROPERTY C_STANDARD 99)
if (WIN32 OR MINGW)
    target_link_libraries(risa PRIVATE wsock32 ws2_32)
    target_compile_options(risa PUBLIC /W3)
    target_compile_options(risa PUBLIC /WX)
else ()
    target_link_libraries(risa ${CMAKE_DL_LIBS})
    target_compile_options(risa PUBLIC -Wall)
    target_compile_options(risa PUBLIC -Werror)
endif()
if (GDBLOG)
    target_compile_definitions(risa PRIVATE GDBLOG)
endif()
add_subdirectory(${CMAKE_SOURCE_DIR}/examples/risa_handler)

# RV32I hello world example
if (BUILD_HELLO_WORLD)
    add_multi_target_component(examples hello_world ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})
endif()

# Verilated core
add_library(Vdrop32_lib STATIC
    ${CMAKE_SOURCE_DIR}/sim/Vdrop32/utils.cc
    ${CMAKE_SOURCE_DIR}/sim/Vdrop32/drop32.cc
)
target_include_directories(Vdrop32_lib PRIVATE
    ${CMAKE_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/sim/Vdrop32
)
add_dependencies(Vdrop32_lib typesVh)

# CLI verilated simulation driver
add_executable(Vdrop32 ${CMAKE_SOURCE_DIR}/sim/Vdrop32/main.cc)
target_include_directories(Vdrop32 PRIVATE
    ${CMAKE_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/sim/Vdrop32
    ${CMAKE_SOURCE_DIR}/external/miniargparse
)
target_link_libraries(Vdrop32 PRIVATE Vdrop32_lib)

# Build RISC-V test sources (CLI GoogleTest driver)
if (BUILD_TESTS)
    find_package(GTest REQUIRED)
    add_multi_target_component(tests basic ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})
    add_multi_target_component(tests algorithms ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})
    add_multi_target_component(external riscv-tests ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})

    add_executable(Vdrop32_tests
        ${CMAKE_SOURCE_DIR}/tests/main.cc
        ${CMAKE_SOURCE_DIR}/tests/test_unit.cc
        ${CMAKE_SOURCE_DIR}/tests/test_basic.cc
        ${CMAKE_SOURCE_DIR}/tests/test_functional.cc
        ${CMAKE_SOURCE_DIR}/tests/test_algorithms.cc
    )
    target_include_directories(Vdrop32_tests PRIVATE
        ${CMAKE_BINARY_DIR}
        ${CMAKE_BINARY_DIR}/${RISCV_TOOLCHAIN_TRIPLE}/basic
        ${CMAKE_BINARY_DIR}/${RISCV_TOOLCHAIN_TRIPLE}/algorithms
        ${CMAKE_BINARY_DIR}/${RISCV_TOOLCHAIN_TRIPLE}/riscv-tests
        ${CMAKE_SOURCE_DIR}/sim/Vdrop32
        ${CMAKE_SOURCE_DIR}/external/miniargparse
    )
    target_link_libraries(Vdrop32_tests PRIVATE
        Vdrop32_lib
        GTest::GTest
        GTest::Main
        ${CMAKE_DL_LIBS}
    )
    add_dependencies(Vdrop32_tests
        typesVh
        Vdrop32_lib
        basic-${RISCV_TOOLCHAIN_TRIPLE}
        algorithms-${RISCV_TOOLCHAIN_TRIPLE}
        riscv-tests-${RISCV_TOOLCHAIN_TRIPLE}
    )
endif ()

# Build example SoC firmware
if (BUILD_SOC)
    add_multi_target_component(examples drop32soc ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})
endif()

# Verilate Verilog RTL to C++
verilate(Vdrop32_lib SOURCES rtl/drop32.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/ALU.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/ControlUnit.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/DualPortRam.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/ImmGen.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/Regfile.v INCLUDE_DIRS rtl TRACE)
