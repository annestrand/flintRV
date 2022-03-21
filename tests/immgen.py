import random
import cocotb

from cocotb.triggers import Timer

@cocotb.test()
async def immgen_test(dut):
    '''Immgen test: [ 0x0a018613 ]: addi    a2,gp,160'''
    signExt = 0
    opcode = 0b00100
    instr = 0x0a018613

    dut.signExt.value = signExt
    dut.opcode.value = opcode
    dut.instr.value = instr

    await Timer(2, units='ns')

    assert dut.imm.value == 160, f"Immgen output is incorrect: {dut.imm.value} != 160"

@cocotb.test()
async def immgen_test2(dut):
    '''Immgen test:  [ 0x04418513 ]: addi    a0,gp,68'''
    signExt = 0
    opcode = 0b00100
    instr = 0x04418513

    dut.signExt.value = signExt
    dut.opcode.value = opcode
    dut.instr.value = instr

    await Timer(2, units='ns')

    assert dut.imm.value == 68, f"Immgen output is incorrect: {dut.imm.value} != 68"
