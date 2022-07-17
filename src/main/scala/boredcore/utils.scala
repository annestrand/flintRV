package boredcore

import chisel3._
import chisel3.util._

object utils {
    object rv32 { // Utilities specific RV32
        def getOpcode(instr: UInt)          : UInt = { return instr(6,0);   }
        def getRs1(instr: UInt)             : UInt = { return instr(19,15); }
        def getRs2(instr: UInt)             : UInt = { return instr(24,20); }
        def getRd(instr: UInt)              : UInt = { return instr(11,7);  }
        def getFunct3(instr: UInt)          : UInt = { return instr(14,12); }
        def getFunct7(instr: UInt)          : UInt = { return instr(31,25); }
        def swapEndianStr(instr: String)    : UInt = {
            if(instr.length() != 8) {
                println(s"Error, $instr is not a 32-bit value! Returning 0...");
                return 0.U;
            }
            return ("h" + instr.substring(6,8) + instr.substring(4,6) + instr.substring(2,4) + instr.substring(0,2)).U;
        }
    }
}
