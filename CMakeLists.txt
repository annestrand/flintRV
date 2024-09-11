cmake_minimum_required(VERSION 3.12)

project(flintRV)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

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

# Simulation utils
add_library(sim_utils ${CMAKE_SOURCE_DIR}/sim/common/utils.cc)
target_include_directories(sim_utils PRIVATE
    ${CMAKE_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/sim
)
add_dependencies(sim_utils typesVh)

# C-based functional RV32I simulator
add_executable(risa
    ${CMAKE_SOURCE_DIR}/sim/risa/main.cc
    ${CMAKE_SOURCE_DIR}/sim/risa/risa.cc
    ${CMAKE_SOURCE_DIR}/sim/risa/socket.cc
    ${CMAKE_SOURCE_DIR}/sim/risa/handlers.cc
    ${CMAKE_SOURCE_DIR}/sim/risa/gdbserver.cc
)
target_include_directories(risa PUBLIC
    ${CMAKE_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/sim
    ${CMAKE_SOURCE_DIR}/external
)
if (WIN32 OR MINGW)
    target_link_libraries(risa PRIVATE wsock32 ws2_32)
    target_compile_options(risa PUBLIC /W3)
    target_compile_options(risa PUBLIC /WX)
else ()
    target_link_libraries(risa PRIVATE ${CMAKE_DL_LIBS})
    target_compile_options(risa PUBLIC -Wall)
    target_compile_options(risa PUBLIC -Werror)
endif()
if (GDBLOG)
    target_compile_definitions(risa PRIVATE GDBLOG)
endif()
target_link_libraries(risa PRIVATE sim_utils)
add_subdirectory(${CMAKE_SOURCE_DIR}/examples/risa_handler)

# Verilated core
add_library(flintRV_lib STATIC ${CMAKE_SOURCE_DIR}/sim/flintRV/flintRV.cc)
target_include_directories(flintRV_lib PRIVATE ${CMAKE_SOURCE_DIR}/sim)

# CLI verilated simulation driver
add_executable(flintRV ${CMAKE_SOURCE_DIR}/sim/flintRV/main.cc)
target_include_directories(flintRV PRIVATE
    ${CMAKE_BINARY_DIR}
    ${CMAKE_SOURCE_DIR}/sim
    ${CMAKE_SOURCE_DIR}/external
)
target_link_libraries(flintRV PRIVATE
    flintRV_lib
    sim_utils
)

# Build RISC-V test sources (CLI GoogleTest driver)
if (BUILD_TESTS)
    find_package(GTest REQUIRED)
    add_multi_target_component(tests basic ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})
    add_multi_target_component(tests algorithms ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})
    add_multi_target_component(external riscv-tests ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})

    add_executable(flintRV_tests
        ${CMAKE_SOURCE_DIR}/tests/main.cc
        ${CMAKE_SOURCE_DIR}/tests/test_unit.cc
        ${CMAKE_SOURCE_DIR}/tests/test_basic.cc
        ${CMAKE_SOURCE_DIR}/tests/test_functional.cc
        ${CMAKE_SOURCE_DIR}/tests/test_algorithms.cc
    )
    target_include_directories(flintRV_tests PRIVATE
        ${CMAKE_BINARY_DIR}
        ${CMAKE_BINARY_DIR}/${RISCV_TOOLCHAIN_TRIPLE}/basic
        ${CMAKE_BINARY_DIR}/${RISCV_TOOLCHAIN_TRIPLE}/algorithms
        ${CMAKE_BINARY_DIR}/${RISCV_TOOLCHAIN_TRIPLE}/riscv-tests
        ${CMAKE_SOURCE_DIR}/sim
        ${CMAKE_SOURCE_DIR}/external
    )
    target_link_libraries(flintRV_tests PRIVATE
        flintRV_lib
        GTest::GTest
        GTest::Main
        ${CMAKE_DL_LIBS}
        sim_utils
    )
    add_dependencies(flintRV_tests
        typesVh
        flintRV_lib
        basic-${RISCV_TOOLCHAIN_TRIPLE}
        algorithms-${RISCV_TOOLCHAIN_TRIPLE}
        riscv-tests-${RISCV_TOOLCHAIN_TRIPLE}
    )
endif ()

# RV32I hello world example
if (BUILD_HELLO_WORLD)
    add_multi_target_component(examples hello_world ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})
endif()

# Build example SoC firmware
if (BUILD_SOC)
    add_multi_target_component(examples flintRVsoc ${RISCV_TOOLCHAIN_TRIPLE} ${EXTERN_PROJECT_GENERATOR})
endif()

# Verilate Verilog RTL to C++
verilate(flintRV_lib SOURCES rtl/flintRV.v INCLUDE_DIRS rtl TRACE)
verilate(flintRV_lib SOURCES rtl/ALU.v INCLUDE_DIRS rtl TRACE)
verilate(flintRV_lib SOURCES rtl/ControlUnit.v INCLUDE_DIRS rtl TRACE)
verilate(flintRV_lib SOURCES rtl/DualPortRam.v INCLUDE_DIRS rtl TRACE)
verilate(flintRV_lib SOURCES rtl/ImmGen.v INCLUDE_DIRS rtl TRACE)
verilate(flintRV_lib SOURCES rtl/Regfile.v INCLUDE_DIRS rtl TRACE)
