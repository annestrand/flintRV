// Copyright (c) 2022 - present, Austin Annestrand.
// Licensed under the MIT License (see LICENSE file).

`include "types.vh"

module ControlUnit (
    input       [4:0]       i_opcode,
    input       [2:0]       i_funct3,
    output      [12:0]      o_ctrlSigs
);
    localparam
    //  Format ctrl sigs:     { EXEC_A | EXEC_B | MEM_W  | REG_W  | MEM2REG | BRA     | JMP    }
        R_CTRL          `VP=  { `REG   , `REG   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE },
        S_CTRL          `VP=  { `REG   , `IMM   , `TRUE  , `FALSE , `FALSE  , `FALSE  , `FALSE },
        B_CTRL          `VP=  { `REG   , `REG   , `FALSE , `FALSE , `FALSE  , `TRUE   , `FALSE },
        J_CTRL          `VP=  { `PC    , `REG   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `TRUE  },
        LUI_CTRL        `VP=  { `REG   , `IMM   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE },
        AUIPC_CTRL      `VP=  { `PC    , `IMM   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE },
        FENCE_CTRL      `VP=  { `REG   , `IMM   , `FALSE , `FALSE , `FALSE  , `FALSE  , `FALSE },
        SYSTEM_CTRL     `VP=  { `REG   , `IMM   , `FALSE , `FALSE , `FALSE  , `FALSE  , `FALSE },
        I_JUMP_CTRL     `VP=  { `PC    , `REG   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `TRUE  },
        I_LOAD_CTRL     `VP=  { `REG   , `IMM   , `FALSE , `TRUE  , `TRUE   , `FALSE  , `FALSE },
        I_ARITH_CTRL    `VP=  { `REG   , `IMM   , `FALSE , `TRUE  , `FALSE  , `FALSE  , `FALSE },
        INVALID_CTRL    `VP=  { `REG   , `REG   , `FALSE , `FALSE , `FALSE  , `FALSE  , `FALSE };

    // Control Memory values
    localparam
    //  Instr:         {  BRK  |  SYS  |  ALU_OP        | FMT_CTRL      }
        LUI     `VP=   { `FALSE, `FALSE, `ALU_OP_LUI    , LUI_CTRL      },
        AUIPC   `VP=   { `FALSE, `FALSE, `ALU_OP_AUIPC  , AUIPC_CTRL    },
        JAL     `VP=   { `FALSE, `FALSE, `ALU_OP_J      , J_CTRL        },
        JALR    `VP=   { `FALSE, `FALSE, `ALU_OP_I_JUMP , I_JUMP_CTRL   },
        BEQ     `VP=   { `FALSE, `FALSE, `ALU_OP_B      , B_CTRL        },
        BNE     `VP=   { `FALSE, `FALSE, `ALU_OP_B      , B_CTRL        },
        BLT     `VP=   { `FALSE, `FALSE, `ALU_OP_B      , B_CTRL        },
        BGE     `VP=   { `FALSE, `FALSE, `ALU_OP_B      , B_CTRL        },
        BLTU    `VP=   { `FALSE, `FALSE, `ALU_OP_B      , B_CTRL        },
        BGEU    `VP=   { `FALSE, `FALSE, `ALU_OP_B      , B_CTRL        },
        LB      `VP=   { `FALSE, `FALSE, `ALU_OP_I_LOAD , I_LOAD_CTRL   },
        LH      `VP=   { `FALSE, `FALSE, `ALU_OP_I_LOAD , I_LOAD_CTRL   },
        LW      `VP=   { `FALSE, `FALSE, `ALU_OP_I_LOAD , I_LOAD_CTRL   },
        LBU     `VP=   { `FALSE, `FALSE, `ALU_OP_I_LOAD , I_LOAD_CTRL   },
        LHU     `VP=   { `FALSE, `FALSE, `ALU_OP_I_LOAD , I_LOAD_CTRL   },
        SB      `VP=   { `FALSE, `FALSE, `ALU_OP_S      , S_CTRL        },
        SH      `VP=   { `FALSE, `FALSE, `ALU_OP_S      , S_CTRL        },
        SW      `VP=   { `FALSE, `FALSE, `ALU_OP_S      , S_CTRL        },
        ADDI    `VP=   { `FALSE, `FALSE, `ALU_OP_I_ARITH, I_ARITH_CTRL  },
        SLTI    `VP=   { `FALSE, `FALSE, `ALU_OP_I_ARITH, I_ARITH_CTRL  },
        SLTIU   `VP=   { `FALSE, `FALSE, `ALU_OP_I_ARITH, I_ARITH_CTRL  },
        XORI    `VP=   { `FALSE, `FALSE, `ALU_OP_I_ARITH, I_ARITH_CTRL  },
        ORI     `VP=   { `FALSE, `FALSE, `ALU_OP_I_ARITH, I_ARITH_CTRL  },
        ANDI    `VP=   { `FALSE, `FALSE, `ALU_OP_I_ARITH, I_ARITH_CTRL  },
        SLLI    `VP=   { `FALSE, `FALSE, `ALU_OP_I_ARITH, I_ARITH_CTRL  },
        SRxI    `VP=   { `FALSE, `FALSE, `ALU_OP_I_ARITH, I_ARITH_CTRL  }, // (i.e. SRAI and SRLI)
        ADDSUB  `VP=   { `FALSE, `FALSE, `ALU_OP_R      , R_CTRL        }, // (i.e. ADD and SUB)
        SLL     `VP=   { `FALSE, `FALSE, `ALU_OP_R      , R_CTRL        },
        SLT     `VP=   { `FALSE, `FALSE, `ALU_OP_R      , R_CTRL        },
        SLTU    `VP=   { `FALSE, `FALSE, `ALU_OP_R      , R_CTRL        },
        XOR     `VP=   { `FALSE, `FALSE, `ALU_OP_R      , R_CTRL        },
        SRx     `VP=   { `FALSE, `FALSE, `ALU_OP_R      , R_CTRL        }, // (i.e. SRL and SRA)
        OR      `VP=   { `FALSE, `FALSE, `ALU_OP_R      , R_CTRL        },
        AND     `VP=   { `FALSE, `FALSE, `ALU_OP_R      , R_CTRL        },
        FENCE   `VP=   { `FALSE, `FALSE, `ALU_OP_FENCE  , FENCE_CTRL    },
        ECALL   `VP=   { `FALSE, `TRUE , `ALU_OP_SYS    , SYSTEM_CTRL   },
        INVALID `VP=   { `TRUE , `FALSE, `ALU_OP_R      , INVALID_CTRL  };

    reg[12:0] cm_out;
    reg[12:0] funct_cm_out;

    // Control Unit decoding
    always @(*) begin
        casez ({i_funct3, i_opcode})
            {3'b???, `LUI}      : cm_out = LUI;
            {3'b???, `AUIPC}    : cm_out = AUIPC;
            {3'b???, `JAL}      : cm_out = JAL;
            {3'b???, `JALR}     : cm_out = JALR;
            {3'b000, `LOAD}     : cm_out = LB;
            {3'b001, `LOAD}     : cm_out = LH;
            {3'b010, `LOAD}     : cm_out = LW;
            {3'b100, `LOAD}     : cm_out = LBU;
            {3'b101, `LOAD}     : cm_out = LHU;
            {3'b000, `STORE}    : cm_out = SB;
            {3'b001, `STORE}    : cm_out = SH;
            {3'b010, `STORE}    : cm_out = SW;
            {3'b000, `BRANCH}   : cm_out = BEQ;
            {3'b001, `BRANCH}   : cm_out = BNE;
            {3'b100, `BRANCH}   : cm_out = BLT;
            {3'b101, `BRANCH}   : cm_out = BGE;
            {3'b110, `BRANCH}   : cm_out = BLTU;
            {3'b111, `BRANCH}   : cm_out = BGEU;
            {3'b000, `OP_IMM}   : cm_out = ADDI;
            {3'b010, `OP_IMM}   : cm_out = SLTI;
            {3'b011, `OP_IMM}   : cm_out = SLTIU;
            {3'b100, `OP_IMM}   : cm_out = XORI;
            {3'b110, `OP_IMM}   : cm_out = ORI;
            {3'b111, `OP_IMM}   : cm_out = ANDI;
            {3'b001, `OP_IMM}   : cm_out = SLLI;
            {3'b101, `OP_IMM}   : cm_out = SRxI;
            {3'b000, `SYSTEM}   : cm_out = ECALL;
            {3'b000, `MISC_MEM} : cm_out = FENCE;
            default             : cm_out = INVALID;
        endcase
        // Funct Control Unit decoding
        case (i_funct3)
            3'b000  : funct_cm_out = ADDSUB;
            3'b001  : funct_cm_out = SLL;
            3'b010  : funct_cm_out = SLT;
            3'b011  : funct_cm_out = SLTU;
            3'b100  : funct_cm_out = XOR;
            3'b101  : funct_cm_out = SRx;
            3'b110  : funct_cm_out = OR;
            3'b111  : funct_cm_out = AND;
            default : funct_cm_out = INVALID;
        endcase
    end

    // Output logic
    wire fcm_sel        = i_opcode == `OP; // (i.e. RV32I R-type)
    assign o_ctrlSigs   = fcm_sel ? funct_cm_out : cm_out;

endmodule
