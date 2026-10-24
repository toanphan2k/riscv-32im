//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-07
// Design Name:
// Module Name: id_decoder_ctrl
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the id_decoder_ctrl module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module id_decoder_ctrl (
    input  logic [XLEN-1:0]             instr,
    output ctrl_signal_t                ctrl,
    output logic [REG_ADDR_WIDTH-1:0]   rs1_addr,
    output logic [REG_ADDR_WIDTH-1:0]   rs2_addr,
    output logic [REG_ADDR_WIDTH-1:0]   rd_addr
);
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign rd_addr  = instr[11:7];

    always_comb begin : DECODER_SIGNAL_CTRL
        ctrl.en_reg_write   = 1'b0;
        ctrl.en_mem_read    = 1'b0;
        ctrl.en_mem_write   = 1'b0;
        ctrl.en_branch      = 1'b0;
        ctrl.en_m_ext       = 1'b0;
        ctrl.en_jalr        = 1'b0;
        ctrl.en_jump        = 1'b0;
        ctrl.alu_opcode     = ALU_ADD;
        ctrl.m_ext_opcode   = M_MUL;
        ctrl.alu_src_a_sel  = ALU_SRC_A_RS1;
        ctrl.alu_src_b_sel  = ALU_SRC_B_RS2;
        ctrl.wb_src_sel     = WB_SRC_ALU;
        ctrl.funct3         = funct3;
        ctrl.is_fence       = 1'b0;
        ctrl.is_ecall       = 1'b0;
        ctrl.is_ebreak      = 1'b0;
        ctrl.illegal_instr  = 1'b0;
        ctrl.uses_rs1       = 1'b0;
        ctrl.uses_rs2       = 1'b0;

        case (opcode)
            OP_IMM: begin
                // Similar to OP_REG but RS2 is IMM
                ctrl.uses_rs1      = 1'b1;
                ctrl.en_reg_write  = 1'b1;
                ctrl.alu_src_a_sel = ALU_SRC_A_RS1;
                ctrl.alu_src_b_sel = ALU_SRC_B_IMM;
                ctrl.wb_src_sel    = WB_SRC_ALU;
                case (funct3)
                    ADD:        ctrl.alu_opcode = ALU_ADD;
                    SLT:        ctrl.alu_opcode = ALU_SLT;
                    SLTU:       ctrl.alu_opcode = ALU_SLTU;
                    XOR:        ctrl.alu_opcode = ALU_XOR;
                    OR:         ctrl.alu_opcode = ALU_OR;
                    AND:        ctrl.alu_opcode = ALU_AND;
                    SLL:        ctrl.alu_opcode = ALU_SLL;
                    SHIFT:      ctrl.alu_opcode = funct7[5] ? ALU_SRA : ALU_SRL;
                    default:    ctrl.illegal_instr = 1'b1;
                endcase
            end

            OP_REG: begin
                ctrl.uses_rs1      = 1'b1;
                ctrl.uses_rs2      = 1'b1;
                ctrl.en_reg_write  = 1'b1;
                ctrl.alu_src_a_sel = ALU_SRC_A_RS1;
                ctrl.alu_src_b_sel = ALU_SRC_B_RS2;

                if (funct7 == FUNCT7_M) begin
                    ctrl.en_m_ext = 1'b1;
                    ctrl.wb_src_sel = WB_SRC_M_EXT;
                    case (funct3)
                        M_MUL:      ctrl.m_ext_opcode = M_MUL;
                        M_MULH:     ctrl.m_ext_opcode = M_MULH;
                        M_MULHSU:   ctrl.m_ext_opcode = M_MULHSU;
                        M_MULHU:    ctrl.m_ext_opcode = M_MULHU;
                        M_DIV:      ctrl.m_ext_opcode = M_DIV;
                        M_DIVU:     ctrl.m_ext_opcode = M_DIVU;
                        M_REM:      ctrl.m_ext_opcode = M_REM;
                        M_REMU:     ctrl.m_ext_opcode = M_REMU;
                        default:    ctrl.illegal_instr = 1'b1;
                    endcase
                end else if (funct7 == FUNCT7_I || funct7 == FUNCT7_I_SHIFT) begin
                    ctrl.wb_src_sel = WB_SRC_ALU;
                    case (funct3)
                        ADD:        ctrl.alu_opcode = funct7[5] ? ALU_SUB : ALU_ADD;
                        SLT:        ctrl.alu_opcode = ALU_SLT;
                        SLTU:       ctrl.alu_opcode = ALU_SLTU;
                        XOR:        ctrl.alu_opcode = ALU_XOR;
                        OR:         ctrl.alu_opcode = ALU_OR;
                        AND:        ctrl.alu_opcode = ALU_AND;
                        SLL:        ctrl.alu_opcode = ALU_SLL;
                        SHIFT:      ctrl.alu_opcode = funct7[5] ? ALU_SRA : ALU_SRL;
                        default:    ctrl.illegal_instr = 1'b1;
                    endcase
                end else begin
                    ctrl.illegal_instr = 1'b1;
                end
            end

            OP_LOAD: begin
                ctrl.en_reg_write   = 1'b1;
                ctrl.uses_rs1       = 1'b1;
                ctrl.en_mem_read    = 1'b1;
                ctrl.alu_src_a_sel  = ALU_SRC_A_RS1;
                ctrl.alu_src_b_sel  = ALU_SRC_B_IMM;
                ctrl.alu_opcode     = ALU_ADD;
                ctrl.wb_src_sel     = WB_SRC_MEM;
            end

            OP_STORE: begin
                ctrl.uses_rs1       = 1'b1;
                ctrl.uses_rs2       = 1'b1;
                ctrl.en_mem_write   = 1'b1;
                ctrl.alu_src_a_sel  = ALU_SRC_A_RS1;
                ctrl.alu_src_b_sel  = ALU_SRC_B_IMM;
                ctrl.alu_opcode     = ALU_ADD;
            end

            OP_BRANCH: begin
                ctrl.uses_rs1       = 1'b1;
                ctrl.uses_rs2       = 1'b1;
                ctrl.en_branch      = 1'b1;
                ctrl.alu_src_a_sel  = ALU_SRC_A_RS1;
                ctrl.alu_src_b_sel  = ALU_SRC_B_RS2;
                case (funct3)
                    BR_BEQ, BR_BNE:   ctrl.alu_opcode     = ALU_SUB;
                    BR_BLT, BR_BGE:   ctrl.alu_opcode     = ALU_SLT;
                    BR_BLTU, BR_BGEU: ctrl.alu_opcode     = ALU_SLTU;
                    default: ctrl.alu_opcode              = ALU_SUB;
                endcase
            end

            OP_LUI: begin
                ctrl.en_reg_write   = 1'b1;
                ctrl.alu_src_a_sel  = ALU_SRC_A_ZERO;
                ctrl.alu_src_b_sel  = ALU_SRC_B_IMM;
                ctrl.alu_opcode     = ALU_ADD;
                ctrl.wb_src_sel     = WB_SRC_ALU;
            end

            OP_AUIPC: begin
                ctrl.en_reg_write   = 1'b1;
                ctrl.alu_src_a_sel  = ALU_SRC_A_PC;
                ctrl.alu_src_b_sel  = ALU_SRC_B_IMM;
                ctrl.alu_opcode     = ALU_ADD;
                ctrl.wb_src_sel     = WB_SRC_ALU;
            end

            OP_JAL: begin
                ctrl.en_jump        = 1'b1;
                ctrl.en_reg_write   = 1'b1;
                ctrl.alu_src_a_sel  = ALU_SRC_A_PC;
                ctrl.alu_src_b_sel  = ALU_SRC_B_IMM;
                ctrl.alu_opcode     = ALU_ADD;
                ctrl.wb_src_sel     = WB_SRC_PC_4;
            end

            OP_JALR: begin
                ctrl.uses_rs1       = 1'b1;
                ctrl.en_jump        = 1'b1;
                ctrl.en_jalr        = 1'b1;
                ctrl.en_reg_write   = 1'b1;
                ctrl.alu_src_a_sel  = ALU_SRC_A_PC;
                ctrl.alu_src_b_sel  = ALU_SRC_B_IMM;
                ctrl.alu_opcode     = ALU_ADD;
                ctrl.wb_src_sel     = WB_SRC_PC_4;
            end

            OP_FENCE: begin
                ctrl.is_fence = 1'b1;
            end

            OP_SYSTEM: begin
                case(funct3)
                    ENV: begin
                        case(instr[31:20])
                            12'h000: ctrl.is_ecall  = 1'b1;
                            12'h001: ctrl.is_ebreak = 1'b1;
                        endcase
                    end
                    default:
                        ctrl.illegal_instr = 1'b1;
                endcase
            end

            default: begin
                ctrl.illegal_instr = 1'b1;
            end
        endcase
    end

endmodule
