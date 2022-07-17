package boredcore

import chisel3._
import chisel3.util._

object utils {
    object rv32 { // Utilities specific RV32
        def getOpcode(instr: UInt)  : UInt = { return instr(6,0);   }
        def getRs1(instr: UInt)     : UInt = { return instr(19,15); }
        def getRs2(instr: UInt)     : UInt = { return instr(24,20); }
        def getRd(instr: UInt)      : UInt = { return instr(11,7);  }
        def getFunct3(instr: UInt)  : UInt = { return instr(14,12); }
        def getFunct7(instr: UInt)  : UInt = { return instr(31,25); }
    }
}
