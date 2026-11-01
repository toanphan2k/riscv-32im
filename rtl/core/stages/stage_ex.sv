//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-09-28
// Design Name:
// Module Name: stage_ex
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the stage_ex module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module stage_ex (
    input  logic                    clk,
    input  logic                    rst_n,
    // Inputs from ID/EX stage
    input  ctrl_signal_t            ex_in_ctrl,
    input  logic [XLEN-1:0]         ex_pc,
    input  logic [XLEN-1:0]         ex_pc4,
    input  logic [XLEN-1:0]         ex_rs1_data,
    input  logic [XLEN-1:0]         ex_rs2_data,
    input  logic [XLEN-1:0]         ex_imm,
    input  logic [REG_ADDR_WIDTH-1:0]   ex_rd_addr,
    // Forwarding select signals
    input  fwd_sel_e                sel_a,
    input  fwd_sel_e                sel_b,
    input  logic [XLEN-1:0]         fwd_mem_data,
    input  logic [XLEN-1:0]         fwd_wb_data,
    // Outputs to EX/MEM Register
    output ctrl_signal_t            ex_out_ctrl,
    output logic [XLEN-1:0]         ex_out_pc4,
    output logic [XLEN-1:0]         ex_out_alu_result,
    output logic [XLEN-1:0]         ex_out_m_unit_result,
    output logic [XLEN-1:0]         ex_out_rs2_data,
    output logic [REG_ADDR_WIDTH-1:0]    ex_out_rd_addr,
    // Branch / Jump feedback to IF stage
    output logic                    branch_taken,
    output logic [XLEN-1:0]         branch_target_addr,
    // Stall signal to Hazard Unit
    output logic                    m_unit_busy

);

    logic [XLEN-1:0]    alu_operand_a;
    logic [XLEN-1:0]    alu_operand_b;
    logic [XLEN-1:0]    fwd_rs1_data;
    logic [XLEN-1:0]    fwd_rs2_data;

    logic               br_cond_met;

    // Block 1:
    // Forwarding MUX for RS1
    always_comb begin : FORWADING_RS1
        case (sel_a)
            FWD_MEM:  fwd_rs1_data = fwd_mem_data;
            FWD_WB:   fwd_rs1_data = fwd_wb_data;
            default:  fwd_rs1_data = ex_rs1_data;
        endcase
    end
    // Forwarding MUX for RS2
    always_comb begin : FORWADING_RS2
        case (sel_b)
            FWD_MEM:  fwd_rs2_data = fwd_mem_data;
            FWD_WB:   fwd_rs2_data = fwd_wb_data;
            default:  fwd_rs2_data = ex_rs2_data;
        endcase
    end

    // Block 2: ALU Operand Selection
    always_comb begin: ALU_OPERAND_A_SEL
        case(ex_in_ctrl.alu_src_a_sel)
            ALU_SRC_A_RS1:  alu_operand_a = fwd_rs1_data;
            ALU_SRC_A_PC:   alu_operand_a = ex_pc;
            ALU_SRC_A_ZERO: alu_operand_a = 32'b0;
            default:        alu_operand_a = fwd_rs1_data;
        endcase
    end

    always_comb begin: ALU_OPERAND_B_SEL
        case(ex_in_ctrl.alu_src_b_sel)
            ALU_SRC_B_RS2:  alu_operand_b = fwd_rs2_data;
            ALU_SRC_B_IMM:  alu_operand_b = ex_imm;
            default:        alu_operand_b = fwd_rs2_data;
        endcase
    end

    // Block 3.1: ALU  Operation
    alu_rv32 alu32_u (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .opcode(ex_in_ctrl.alu_opcode),
        .result(ex_out_alu_result),
        .zero_flag(),
        .less_than_flag(),
        .less_than_unsigned_flag()
    );

    // Block 3.2: M_EXT_UNIT Operation
    m_extesion_unit m_ext_u (
        .clk(clk),
        .rst_n(rst_n),
        .start(ex_in_ctrl.en_m_ext),
        .m_opcode(ex_in_ctrl.m_ext_opcode),
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .m_result(ex_out_m_unit_result),
        .is_busy(m_unit_busy),
        .done() // Not used in this stage, but can be used for future enhancements
    );

    // Block 4: Branch Evaluation
    always_comb begin : BRANCH_EVALUATION
        case (ex_in_ctrl.funct3)
            BR_BEQ:  br_cond_met = (fwd_rs1_data == fwd_rs2_data);
            BR_BNE:  br_cond_met = (fwd_rs1_data != fwd_rs2_data);
            BR_BLT:  br_cond_met = ($signed(fwd_rs1_data) < $signed(fwd_rs2_data));
            BR_BGE:  br_cond_met = ($signed(fwd_rs1_data) >= $signed(fwd_rs2_data));
            BR_BLTU: br_cond_met = (fwd_rs1_data < fwd_rs2_data);
            BR_BGEU: br_cond_met = (fwd_rs1_data >= fwd_rs2_data);
            default: br_cond_met = 1'b0;
        endcase
    end

    // Block 5: Branch Target Calculation
    assign branch_taken       = (ex_in_ctrl.en_branch && br_cond_met) || ex_in_ctrl.en_jump;
    assign branch_target_addr = ex_in_ctrl.en_jalr ?
                                ((fwd_rs1_data + ex_imm) & 32'hFFFF_FFFE) :
                                (ex_pc + ex_imm);

    // Block 6: Outputs to EX/MEM Register
    assign ex_out_ctrl = ex_in_ctrl;
    assign ex_out_rs2_data = fwd_rs2_data;
    assign ex_out_pc4 = ex_pc4;
    assign ex_out_rd_addr = ex_rd_addr;

endmodule
