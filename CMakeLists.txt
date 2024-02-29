cmake_minimum_required(VERSION 3.12)

project(drop32)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})

# User adjustable vars/options
# ---------------------------------------------------------------------------------------------------------------------
set(RISCV_TOOLCHAIN_TRIPLE "riscv64-unknown-elf" CACHE STRING "RISC-V cross-compiler GCC triplet prefix value")
set(EXTERN_PROJECT_GENERATOR "Ninja" CACHE STRING "Generator for external projects (i.e. riscv cross compilation)")
# ---------------------------------------------------------------------------------------------------------------------
option(BUILD_SOC OFF)
option(BUILD_TESTS OFF)
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

# Verilated core
add_library(Vdrop32_lib STATIC
    ${CMAKE_SOURCE_DIR}/sim/verilator/utils.cc
    ${CMAKE_SOURCE_DIR}/sim/verilator/drop32.cc
)
target_include_directories(Vdrop32_lib PRIVATE
    ${CMAKE_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/sim/verilator
)
add_dependencies(Vdrop32_lib typesVh)

# CLI verilated simulation driver
add_executable(Vdrop32 ${CMAKE_SOURCE_DIR}/sim/verilator/main.cc)
target_include_directories(Vdrop32 PRIVATE
    ${CMAKE_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/sim/verilator
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
        ${CMAKE_SOURCE_DIR}/sim/verilator
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
