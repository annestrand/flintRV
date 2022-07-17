package boredcore

import chisel3._
import chisel3.util._

import types._

class Alu(width: Int) extends Module {
    val io = IO(new Bundle {
        val i_aIn   = Input(UInt(width.W))
        val i_bIn   = Input(UInt(width.W))
        val i_op    = Input(UInt(log2Ceil(16).W))
        val o_out   = Output(UInt(width.W))
    })
    val op = io.i_op;
    val a = io.i_aIn;
    val b = Mux(op === types.alu.add4a, 4.U(width.W), io.i_bIn);
    val result = WireDefault(0.U(width.W));
    val isSub = WireDefault(false.B)
    switch (op) {
        is (types.alu.sub)      { isSub := true.B; }
        is (types.alu.slt)      { isSub := true.B; }
        is (types.alu.sltu)     { isSub := true.B; }
        is (types.alu.sgte)     { isSub := true.B; }
        is (types.alu.sgteu)    { isSub := true.B; }
    }
    val addSubResult = io.i_aIn +& Mux(isSub, ~io.i_bIn, io.i_bIn) +& isSub;
    val xorResult = io.i_aIn ^ io.i_bIn;
    val sltBit = WireDefault(0.U(1.W));
    // SLT setup
    switch (a(width-1) ## b(width-1)) {
        is ("b00".U) { sltBit := addSubResult(31); }
        is ("b01".U) { sltBit := "b0".U; } // a > b since a is pos.
        is ("b10".U) { sltBit := "b1".U; } // a < b since a is neg.
        is ("b11".U) { sltBit := addSubResult(31); }
    }
    // Main ALU ops
    switch (op) {
        is (types.alu.add)      { result := addSubResult;                       }
        is (types.alu.sub)      { result := addSubResult;                       }
        is (types.alu.and)      { result := a & b;                              }
        is (types.alu.or )      { result := a | b;                              }
        is (types.alu.xor)      { result := xorResult;                          }
        is (types.alu.sll)      { result := a << b(log2Ceil(width),0);          }
        is (types.alu.srl)      { result := a >> b;                             }
        is (types.alu.sra)      { result := (a.asSInt >> b).asUInt;             }
        is (types.alu.passb)    { result := b;                                  }
        is (types.alu.add4a)    { result := addSubResult;                       }
        is (types.alu.eq)       { result := 0.U(31.W) ## ~xorResult.asUInt.orR; }
        is (types.alu.neq)      { result := 0.U(31.W) ## xorResult.asUInt.orR;  }
        is (types.alu.slt)      { result := 0.U(31.W) ## sltBit;                }
        is (types.alu.sgte)     { result := 0.U(31.W) ## ~sltBit;               }
        is (types.alu.sltu)     { result := 0.U(31.W) ## ~addSubResult(32)      }
        is (types.alu.sgteu)    { result := 0.U(31.W) ## addSubResult(32)       }
    }
    io.o_out := result;
}

object AluGen extends App {
  println("Generating the Alu hardware")
  emitVerilog(new Alu(32), Array("--target-dir", "generated"))
  println("\nDone.")
}