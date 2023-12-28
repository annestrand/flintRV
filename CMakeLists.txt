cmake_minimum_required(VERSION 3.12)

project(drop32)
find_package(verilator HINTS $ENV{VERILATOR_ROOT})

# Generate C/C++ header of types.vh
# TODO: Make this routine a python script for portability
add_custom_target(typesVh
    COMMAND sed "'s/`/#/g'" ${CMAKE_SOURCE_DIR}/rtl/types.vh |
            sed "\"s/[0-9]*'/0/g\"" |
            awk "'!/{/'" |
            awk "'!/x\\[/'" >
            ${CMAKE_BINARY_DIR}/types.h
)

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
add_dependencies(Vdrop32 typesVh)

# Verilate Verilog RTL to C++
verilate(Vdrop32_lib SOURCES rtl/drop32.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/ALU.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/ControlUnit.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/DualPortRam.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/ImmGen.v INCLUDE_DIRS rtl TRACE)
verilate(Vdrop32_lib SOURCES rtl/Regfile.v INCLUDE_DIRS rtl TRACE)

# TODO: Still need to implement the following
#   - Test building
#   - ELF -> HEX -> XXD (C-header)
#   - Docker handling
