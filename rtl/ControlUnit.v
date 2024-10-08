// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module ControlUnit (
    input       [4:0]       i_opcode,
    input       [2:0]       i_funct3,
    /* verilator lint_off UNUSED */
    input       [6:0]       i_funct7,
    /* verilator lint_on UNUSED */
    output      [13:0]      o_ctrlSigs
);
    localparam
    //  Format ctrl sigs:  { EXEC_A | EXEC_B | MEM_W  | REG_W  | MEM2REG | BRA     | JMP    }
        R_CTRL          =  { `REG   , `REG   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE },
        S_CTRL          =  { `REG   , `IMM   , `TRUE  , `FALSE , `FALSE  , `FALSE  , `FALSE },
        B_CTRL          =  { `REG   , `REG   , `FALSE , `FALSE , `FALSE  , `TRUE   , `FALSE },
        J_CTRL          =  { `PC    , `REG   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `TRUE  },
        LUI_CTRL        =  { `REG   , `IMM   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE },
        AUIPC_CTRL      =  { `PC    , `IMM   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE },
        FENCE_CTRL      =  { `REG   , `IMM   , `FALSE , `FALSE , `FALSE  , `FALSE  , `FALSE },
        SYSTEM_CTRL     =  { `REG   , `IMM   , `FALSE , `FALSE , `FALSE  , `FALSE  , `FALSE },
        I_JUMP_CTRL     =  { `PC    , `REG   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `TRUE  },
        I_LOAD_CTRL     =  { `REG   , `IMM   , `FALSE , `TRUE  , `TRUE   , `FALSE  , `FALSE },
        I_ARITH_CTRL    =  { `REG   , `IMM   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE },
        INVALID_CTRL    =  { `REG   , `REG   , `FALSE , `FALSE , `FALSE  , `FALSE  , `FALSE };

    // Control Memory values
    localparam
    //  Instr:                          {  BRK  |  SYS  |  ALU_OP        | FMT_CTRL      }
        LUI     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_PASSB  , LUI_CTRL      },
        AUIPC   /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , AUIPC_CTRL    },
        JAL     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD4A  , J_CTRL        },
        JALR    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD4A  , I_JUMP_CTRL   },
        BEQ     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_EQ     , B_CTRL        },
        BNE     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_NEQ    , B_CTRL        },
        BLT     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SLT    , B_CTRL        },
        BGE     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SGTE   , B_CTRL        },
        BLTU    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SLTU   , B_CTRL        },
        BGEU    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SGTEU  , B_CTRL        },
        LB      /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , I_LOAD_CTRL   },
        LH      /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , I_LOAD_CTRL   },
        LW      /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , I_LOAD_CTRL   },
        LBU     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , I_LOAD_CTRL   },
        LHU     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , I_LOAD_CTRL   },
        SB      /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , S_CTRL        },
        SH      /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , S_CTRL        },
        SW      /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , S_CTRL        },
        ADDI    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , I_ARITH_CTRL  },
        SLTI    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SLT    , I_ARITH_CTRL  },
        SLTIU   /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SLTU   , I_ARITH_CTRL  },
        XORI    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_XOR    , I_ARITH_CTRL  },
        ORI     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_OR     , I_ARITH_CTRL  },
        ANDI    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_AND    , I_ARITH_CTRL  },
        SLLI    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SLL    , I_ARITH_CTRL  },
        SRLI    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SRL    , I_ARITH_CTRL  },
        SRAI    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SRA    , I_ARITH_CTRL  },
        ADD     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , R_CTRL        },
        SUB     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SUB    , R_CTRL        },
        SLL     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SLL    , R_CTRL        },
        SLT     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SLT    , R_CTRL        },
        SLTU    /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SLTU   , R_CTRL        },
        XOR     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_XOR    , R_CTRL        },
        SRL     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SRL    , R_CTRL        },
        SRA     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_SRA    , R_CTRL        },
        OR      /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_OR     , R_CTRL        },
        AND     /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_AND    , R_CTRL        },
        FENCE   /*verilator public*/=   { `FALSE, `FALSE, `ALU_OP_ADD    , FENCE_CTRL    },
        ECALL   /*verilator public*/=   { `FALSE, `TRUE , `ALU_OP_ADD    , SYSTEM_CTRL   },
        INVALID /*verilator public*/=   { `TRUE , `FALSE, `ALU_OP_ADD    , INVALID_CTRL  };

    reg[13:0] cm_out;
    reg[13:0] funct_cm_out;

    // Control Unit decoding
    always @(*) begin
        casez ({i_funct3, i_opcode})
            {3'b???, `OP_MAP_LUI}       : cm_out = LUI;
            {3'b???, `OP_MAP_AUIPC}     : cm_out = AUIPC;
            {3'b???, `OP_MAP_JAL}       : cm_out = JAL;
            {3'b???, `OP_MAP_JALR}      : cm_out = JALR;
            {3'b000, `OP_MAP_LOAD}      : cm_out = LB;
            {3'b001, `OP_MAP_LOAD}      : cm_out = LH;
            {3'b010, `OP_MAP_LOAD}      : cm_out = LW;
            {3'b100, `OP_MAP_LOAD}      : cm_out = LBU;
            {3'b101, `OP_MAP_LOAD}      : cm_out = LHU;
            {3'b000, `OP_MAP_STORE}     : cm_out = SB;
            {3'b001, `OP_MAP_STORE}     : cm_out = SH;
            {3'b010, `OP_MAP_STORE}     : cm_out = SW;
            {3'b000, `OP_MAP_BRANCH}    : cm_out = BEQ;
            {3'b001, `OP_MAP_BRANCH}    : cm_out = BNE;
            {3'b100, `OP_MAP_BRANCH}    : cm_out = BLT;
            {3'b101, `OP_MAP_BRANCH}    : cm_out = BGE;
            {3'b110, `OP_MAP_BRANCH}    : cm_out = BLTU;
            {3'b111, `OP_MAP_BRANCH}    : cm_out = BGEU;
            {3'b000, `OP_MAP_OP_IMM}    : cm_out = ADDI;
            {3'b010, `OP_MAP_OP_IMM}    : cm_out = SLTI;
            {3'b011, `OP_MAP_OP_IMM}    : cm_out = SLTIU;
            {3'b100, `OP_MAP_OP_IMM}    : cm_out = XORI;
            {3'b110, `OP_MAP_OP_IMM}    : cm_out = ORI;
            {3'b111, `OP_MAP_OP_IMM}    : cm_out = ANDI;
            {3'b001, `OP_MAP_OP_IMM}    : cm_out = SLLI;
            {3'b101, `OP_MAP_OP_IMM}    : cm_out = i_funct7[5] ? SRAI : SRLI;
            {3'b000, `OP_MAP_SYSTEM}    : cm_out = ECALL;
            {3'b000, `OP_MAP_MISC_MEM}  : cm_out = FENCE;
            default                     : cm_out = INVALID;
        endcase
        // Funct Control Unit decoding
        case (i_funct3)
            3'b000  : funct_cm_out = i_funct7[5] ? SUB : ADD;
            3'b001  : funct_cm_out = SLL;
            3'b010  : funct_cm_out = SLT;
            3'b011  : funct_cm_out = SLTU;
            3'b100  : funct_cm_out = XOR;
            3'b101  : funct_cm_out = i_funct7[5] ? SRA : SRL;
            3'b110  : funct_cm_out = OR;
            3'b111  : funct_cm_out = AND;
            default : funct_cm_out = INVALID;
        endcase
    end

    // Output logic
    wire fcm_sel        = i_opcode == `OP_MAP_OP; // (i.e. RV32I R-type)
    assign o_ctrlSigs   = fcm_sel ? funct_cm_out : cm_out;

endmodule
