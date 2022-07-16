package boredcore

import chisel3._
import chisel3.util._
import chisel3.testers._

class RegFile(width: Int, depth: Int) extends Module {
  val io = IO(new Bundle {
    val i_aAddr   = Input(UInt(log2Ceil(width).W))
    val i_bAddr   = Input(UInt(log2Ceil(width).W))
    val i_wrAddr  = Input(UInt(log2Ceil(width).W))
    val i_wrData  = Input(UInt(width.W))
    val i_wrEn    = Input(Bool())
    val o_aRead   = Output(UInt(width.W))
    val o_bRead   = Output(UInt(width.W))
  })
  /*
    NOTE:   Infer 2 copied/synced BRAMs (i.e. one BRAM per read-port)
            rather than just 1 BRAM. This is somewhat wasteful but is
            simpler. Alternate approach is to have the 2 "banks" configured as 2 halved
            BRAMs w/ additional banking logic for wr_en and output forwarding
            (no duplication with this approach but adds some more Tpcq at the output).
  */
  val memA      = SyncReadMem(depth, UInt(width.W));
  val memB      = SyncReadMem(depth, UInt(width.W));
  // Forwarding needed for read-on-write cases
  val needFwd   = RegNext(io.i_wrEn && (io.i_aAddr === io.i_wrAddr) || (io.i_bAddr === io.i_wrAddr));
  val fwdData   = RegNext(io.i_wrData);
  // Write
  when (io.i_wrEn) { memA.write(io.i_wrAddr, io.i_wrData); memB.write(io.i_wrAddr, io.i_wrData); }
  // Read
  io.o_aRead    := Mux(needFwd, fwdData, memA.read(io.i_aAddr));
  io.o_bRead    := Mux(needFwd, fwdData, memB.read(io.i_bAddr));
}

object RegFileGen extends App {
  println("Generating the RegFile hardware")
  emitVerilog(new RegFile(32, 32), Array("--target-dir", "generated"))
  println("\nDone.")
}
