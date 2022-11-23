// RTL src
`include "ALU_Control.v"
`include "ALU.v"
`include "ControlUnit.v"
`include "DualPortRam.v"
`include "ImmGen.v"
`include "Regfile.v"

// TB src
// TODO: Find a better way of wrapping tests/TBs in 1 program/script
`include "ALU_Control_tb.v"
`include "ALU_tb.v"
`include "ControlUnit_tb.v"
`include "DualPortRam_tb.v"
`include "Regfile_tb.v"
`include "ImmGen_tb.v"
