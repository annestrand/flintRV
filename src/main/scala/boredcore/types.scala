package boredcore

import utils._
import chisel3._
import chisel3.util._

object types {
    object alu {
        val (add :: passb :: add4a :: xor :: srl :: sra :: or :: and :: sub :: sll :: eq :: neq :: slt ::
                sltu :: sgte :: sgteu :: Nil) = Enum(16);
        val (op_r :: op_i_jump :: op_i_load :: op_i_arith :: op_i_sys :: op_i_fence :: op_s :: op_b :: op_u_lui ::
                op_u_auipc :: op_j :: Nil) = Enum(11);
    }
}
