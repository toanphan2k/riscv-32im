//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-11-2
// Design Name:
// Module Name: verdic_32bit_multiplier
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Four 16x16 DSP partial products with carry-save reduction.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module verdic_32bit_multiplier(
    // multiplier using DSP resources
    input  logic [XLEN-1:0] operand_a,
    input  logic [XLEN-1:0] operand_b,
    input  m_ext_opcode_e m_opcode,
    output logic [XLEN-1:0] mul_result
);

    (* use_dsp = "yes" *) logic [31:0] product_ll;
    (* use_dsp = "yes" *) logic [31:0] product_lh;
    (* use_dsp = "yes" *) logic [31:0] product_hl;
    (* use_dsp = "yes" *) logic [31:0] product_hh;

    logic negative_a;
    logic negative_b;
    logic [1:0] correction_count;
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
    (* use_dsp = "no" *) logic [63:0] full_product;

    assign product_ll = operand_a[15:0]  * operand_b[15:0];
    assign product_lh = operand_a[15:0]  * operand_b[31:16];
    assign product_hl = operand_a[31:16] * operand_b[15:0];
    assign product_hh = operand_a[31:16] * operand_b[31:16];

    assign negative_a = operand_a[31] &
                        ((m_opcode == M_MULH) | (m_opcode == M_MULHSU));
    assign negative_b = operand_b[31] & (m_opcode == M_MULH);
    assign correction_count = {negative_a & negative_b,
                               negative_a ^ negative_b};

    assign partial_ll = {30'b0, correction_count, product_ll};
    assign partial_lh = {16'b0, product_lh, 16'b0};
    assign partial_hl = {16'b0, product_hl, 16'b0};
    assign partial_hh = {product_hh, 32'b0};
    assign correction_a = {(~operand_b & {32{negative_a}}), 32'b0};
    assign correction_b = {(~operand_a & {32{negative_b}}), 32'b0};

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

    always_comb begin : MUL_RESULT_SELECTION
        case (m_opcode)
            M_MUL:                      mul_result = full_product[31:0];
            M_MULH, M_MULHSU, M_MULHU:   mul_result = full_product[63:32];
            default:                    mul_result = '0;
        endcase
    end

endmodule