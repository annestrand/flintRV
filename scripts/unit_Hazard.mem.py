#! /usr/bin/env python3

from common import *

def genFwd():
    exec_rs1    = randReg(x0=False)
    exec_rs2    = randReg(x0=False)
    mem_rd      = randReg(x0=False)
    wb_rd       = randReg(x0=False)
    wb_rd_skid  = randReg(x0=False)
    rs1_fetch   = randReg(x0=False)
    rs2_fetch   = randReg(x0=False)
    mem_rd_rw   = randBit()
    wb_rd_rw    = randBit()

    rs1_fwd_mem = mem_rd_rw and (exec_rs1 == mem_rd)
    rs2_fwd_mem = mem_rd_rw and (exec_rs2 == mem_rd)
    rs1_fwd_wb  = not rs1_fwd_mem and wb_rd_rw and (exec_rs1 == wb_rd)
    rs2_fwd_wb  = not rs2_fwd_mem and wb_rd_rw and (exec_rs2 == wb_rd)
    rs1_fwd = f"{rs1_fwd_wb:b}{rs1_fwd_mem:b}"
    rs2_fwd = f"{rs2_fwd_wb:b}{rs2_fwd_mem:b}"
    rs1_fetch_fwd = f"{(rs1_fetch == wb_rd_skid):b}"
    rs2_fetch_fwd = f"{(rs2_fetch == wb_rd_skid):b}"
    in_vec  = (
        f"{mem_rd_rw:b}{wb_rd_rw:b}{exec_rs1:05b}{exec_rs2:05b}{mem_rd:05b}{wb_rd:05b}{wb_rd_skid:05b}" +
        "00000" +
        f"{rs1_fetch:05b}{rs2_fetch:05b}" +
        "00000"
    )
    out_vec = f"{rs1_fwd}{rs2_fwd}{rs1_fetch_fwd}{rs2_fetch_fwd}0000"
    return in_vec, out_vec

def genHzd():
    bra             = randBit()
    jmp             = randBit()
    fetch_valid     = randBit()
    mem_valid       = randBit()
    exec_mem2reg    = randBit()
    fetch_rs1       = randReg(x0=False)
    fetch_rs2       = randReg(x0=False)
    exec_rd         = randReg(x0=False)
    load_stall      = exec_mem2reg and ((fetch_rs1 == exec_rd) or (fetch_rs2 == exec_rd))
    exec_stall      = not mem_valid
    fetch_stall     = not fetch_valid or exec_stall or load_stall
    mem_flush       = exec_stall
    exec_flush      = not exec_stall and (bra or jmp or fetch_stall)
    in_vec          = (
        "00" +
        "0000000000000000000000000" +
        f"{bra:b}{jmp:b}{fetch_valid:b}{mem_valid:b}{exec_mem2reg:b}{fetch_rs1:05b}{fetch_rs2:05b}{exec_rd:05b}"
    )
    out_vec         = f"000000{fetch_stall:b}{exec_stall:b}{exec_flush:b}{mem_flush:b}"
    return in_vec, out_vec

n_vectors = 32

if __name__ == "__main__":
    outfile = f"{basenameNoExt('out', __file__)}_fwd.mem"
    with open(outfile, 'w') as fp:
        outfileGold = f"{basenameNoExt('out', __file__)}_fwd_gold.mem"
        with open(outfileGold, 'w') as fp_gold:
            for i in range(n_vectors):
                # TODO: Add non-random tests too?
                in_vec, out_vec = genFwd()
                print(f"{in_vec}", file=fp)
                print(f"{out_vec}", file=fp_gold)

    outfile = f"{basenameNoExt('out', __file__)}_hzd.mem"
    with open(outfile, 'w') as fp:
        outfileGold = f"{basenameNoExt('out', __file__)}_hzd_gold.mem"
        with open(outfileGold, 'w') as fp_gold:
            for i in range(n_vectors):
                # TODO: Add non-random tests too?
                in_vec, out_vec = genHzd()
                print(f"{in_vec}", file=fp)
                print(f"{out_vec}", file=fp_gold)