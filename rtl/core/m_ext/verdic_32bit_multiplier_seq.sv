//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-11-2
// Design Name:
// Module Name: verdic_32bit_multiplier_seq
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Two-stage multiplier with four 16x16 DSP partial products.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module verdic_32bit_multiplier_seq(
    input  logic            clk,
    input  logic            rst_n,
    input  logic            start,
    input  logic [XLEN-1:0] operand_a,
    input  logic [XLEN-1:0] operand_b,
    input  m_ext_opcode_e   m_opcode,
    output logic [XLEN-1:0] mul_result,
    output logic            is_busy,
    output logic            done
);
    typedef enum logic [1:0] {IDLE, REDUCE, COMPLETE} mul_state_e;
    mul_state_e curr_state, next_state;

    // (* use_dsp = "yes" *) logic [31:0] product_ll_q, product_ll_d;
    // (* use_dsp = "yes" *) logic [31:0] product_lh_q, product_lh_d;
    // (* use_dsp = "yes" *) logic [31:0] product_hl_q, product_hl_d;
    // (* use_dsp = "yes" *) logic [31:0] product_hh_q, product_hh_d;
    logic [31:0] product_ll_q, product_ll_d;
    logic [31:0] product_lh_q, product_lh_d;
    logic [31:0] product_hl_q, product_hl_d;
    logic [31:0] product_hh_q, product_hh_d;

    logic [31:0] correction_a_q, correction_a_d;
    logic [31:0] correction_b_q, correction_b_d;
    logic [1:0] correction_count_q, correction_count_d;
    m_ext_opcode_e m_opcode_q, m_opcode_d;
    logic [XLEN-1:0] mul_result_d;
    logic negative_a;
    logic negative_b;
    logic [63:0] partial_ll;
    logic [63:0] partial_lh;
    logic [63:0] partial_hl;
    logic [63:0] partial_hh;
    logic [63:0] correction_a;
    logic [63:0] correction_b;
    logic [63:0] csa_sum_1;
    logic [63:0] csa_carry_1;
    logic [63:0] csa_sum_2;
    logic [63:0] csa_carry_2;
    logic [63:0] csa_sum_3;
    logic [63:0] csa_carry_3;
    logic [63:0] csa_sum_4;
    logic [63:0] csa_carry_4;
    // (* use_dsp = "no" *) logic [63:0] full_product;
    logic [63:0] full_product;

    assign is_busy = (curr_state == REDUCE);
    assign done = (curr_state == COMPLETE);
    assign negative_a = operand_a[31] &
                        ((m_opcode == M_MULH) | (m_opcode == M_MULHSU));
    assign negative_b = operand_b[31] & (m_opcode == M_MULH);

    assign partial_ll = {30'b0, correction_count_q, product_ll_q};
    assign partial_lh = {16'b0, product_lh_q, 16'b0};
    assign partial_hl = {16'b0, product_hl_q, 16'b0};
    assign partial_hh = {product_hh_q, 32'b0};
    assign correction_a = {correction_a_q, 32'b0};
    assign correction_b = {correction_b_q, 32'b0};

    assign csa_sum_1 = partial_ll ^ partial_lh ^ partial_hl;
    assign csa_carry_1 = ((partial_ll & partial_lh) |
                          (partial_ll & partial_hl) |
                          (partial_lh & partial_hl)) << 1;

    assign csa_sum_2 = partial_hh ^ correction_a ^ correction_b;
    assign csa_carry_2 = ((partial_hh & correction_a) |
                          (partial_hh & correction_b) |
                          (correction_a & correction_b)) << 1;

    assign csa_sum_3 = csa_sum_1 ^ csa_carry_1 ^ csa_sum_2;
    assign csa_carry_3 = ((csa_sum_1 & csa_carry_1) |
                          (csa_sum_1 & csa_sum_2) |
                          (csa_carry_1 & csa_sum_2)) << 1;

    assign csa_sum_4 = csa_sum_3 ^ csa_carry_3 ^ csa_carry_2;
    assign csa_carry_4 = ((csa_sum_3 & csa_carry_3) |
                          (csa_sum_3 & csa_carry_2) |
                          (csa_carry_3 & csa_carry_2)) << 1;

    assign full_product = csa_sum_4 + csa_carry_4;

    always_comb begin
        next_state = curr_state;
        product_ll_d = product_ll_q;
        product_lh_d = product_lh_q;
        product_hl_d = product_hl_q;
        product_hh_d = product_hh_q;
        correction_a_d = correction_a_q;
        correction_b_d = correction_b_q;
        correction_count_d = correction_count_q;
        m_opcode_d = m_opcode_q;
        mul_result_d = mul_result;

        case (curr_state)
            IDLE: begin
                if (start) begin
                    product_ll_d = operand_a[15:0]  * operand_b[15:0];
                    product_lh_d = operand_a[15:0]  * operand_b[31:16];
                    product_hl_d = operand_a[31:16] * operand_b[15:0];
                    product_hh_d = operand_a[31:16] * operand_b[31:16];
                    correction_a_d = ~operand_b & {32{negative_a}};
                    correction_b_d = ~operand_a & {32{negative_b}};
                    correction_count_d = {negative_a & negative_b,
                                          negative_a ^ negative_b};
                    m_opcode_d = m_opcode;
                    next_state = REDUCE;
                end
            end

            REDUCE: begin
                case (m_opcode_q)
                    M_MUL:                    mul_result_d = full_product[31:0];
                    M_MULH, M_MULHSU, M_MULHU: mul_result_d = full_product[63:32];
                    default:                  mul_result_d = '0;
                endcase
                next_state = COMPLETE;
            end

            COMPLETE: next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state         <= IDLE;
            product_ll_q       <= '0;
            product_lh_q       <= '0;
            product_hl_q       <= '0;
            product_hh_q       <= '0;
            correction_a_q     <= '0;
            correction_b_q     <= '0;
            correction_count_q <= '0;
            m_opcode_q         <= M_MUL;
            mul_result         <= '0;
        end else begin
            curr_state         <= next_state;
            product_ll_q       <= product_ll_d;
            product_lh_q       <= product_lh_d;
            product_hl_q       <= product_hl_d;
            product_hh_q       <= product_hh_d;
            correction_a_q     <= correction_a_d;
            correction_b_q     <= correction_b_d;
            correction_count_q <= correction_count_d;
            m_opcode_q         <= m_opcode_d;
            mul_result         <= mul_result_d;
        end
    end
endmodule