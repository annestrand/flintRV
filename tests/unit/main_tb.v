// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

// RTL src
`include "ALU_Control.v"
`include "ControlUnit.v"

// TB src
// TODO: Find a better way of wrapping tests/TBs in 1 program/script
`include "ALU_Control_tb.v"
`include "ControlUnit_tb.v"
