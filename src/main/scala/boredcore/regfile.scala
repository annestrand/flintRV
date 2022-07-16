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
  val mem       = SyncReadMem(depth, UInt(width.W));
  // Forwarding needed for read-on-write cases
  val needFwd   = RegNext(io.i_wrEn && (io.i_aAddr === io.i_wrAddr) || (io.i_bAddr === io.i_wrAddr));
  val fwdData   = RegNext(io.i_wrData);
  // Write
  when (io.i_wrEn) { mem.write(io.i_wrAddr, io.i_wrData); }
  // Read
  io.o_aRead    := Mux(needFwd, fwdData, mem.read(io.i_aAddr));
  io.o_bRead    := Mux(needFwd, fwdData, mem.read(io.i_bAddr));
}

object Test1 extends App {
  println("Generating the RegFile hardware")
  emitVerilog(new RegFile(32, 32), Array("--target-dir", "generated"))
  println("\nDone.")
}
