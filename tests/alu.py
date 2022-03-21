import random
import cocotb

from cocotb.triggers import Timer

@cocotb.test()
async def alu_test(dut):
    '''ALU test'''
    a=5
    b=10
    sel=3

    dut.a.value = a
    dut.b.value = b
    dut.sel.value = sel

    await Timer(2, units='ns')

    assert dut.f.value == 15, f"ALU output is incorrect: {dut.f.value} != 15"
