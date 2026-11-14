//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Toan Phan Minh
//
// Design Name:
// Module Name: radix2_nonres_divider
// Project Name: riscv-32im
// Description: Iterative radix-2 non-restoring divider for the RV32M extension.
//
// Dependencies: rv32im_pkg.sv
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module radix2_nonres_divider(
    input  logic            clk,
    input  logic            rst_n,
    input  logic            start,
    input  logic [XLEN-1:0] operand_a,
    input  logic [XLEN-1:0] operand_b,
    input  m_ext_opcode_e   m_opcode,
    output logic [XLEN-1:0] div_result,
    output logic            is_busy,
    output logic            done
);
    localparam integer COUNT_WIDTH = $clog2(XLEN);

    typedef enum logic [1:0] {
        IDLE,
        ITERATE,
        COMPLETE
    } div_state_e;

    div_state_e curr_state;
    div_state_e next_state;

    logic [XLEN-1:0] quotient_q;
    logic [XLEN-1:0] quotient_d;
    logic [XLEN-1:0] quotient_next;
    logic signed [XLEN:0] remainder_q;
    logic signed [XLEN:0] remainder_d;
    logic signed [XLEN:0] remainder_shift;
    logic signed [XLEN:0] remainder_next;
    logic signed [XLEN:0] remainder_corrected;
    logic signed [XLEN:0] divisor_extended;
    logic [XLEN-1:0] divisor_q;
    logic [XLEN-1:0] divisor_d;
    logic [COUNT_WIDTH-1:0] iteration_q;
    logic [COUNT_WIDTH-1:0] iteration_d;

    logic is_signed;
    logic quotient_negative_q;
    logic quotient_negative_d;
    logic remainder_negative_q;
    logic remainder_negative_d;
    logic is_remainder_q;
    logic is_remainder_d;
    logic valid_opcode;
    logic [XLEN-1:0] div_result_d;

    assign is_signed = (m_opcode == M_DIV) || (m_opcode == M_REM);
    assign valid_opcode = (m_opcode == M_DIV)  ||
                          (m_opcode == M_DIVU) ||
                          (m_opcode == M_REM)  ||
                          (m_opcode == M_REMU);
    assign is_busy = (curr_state == ITERATE);
    assign done = (curr_state == COMPLETE);

    always_comb begin
        remainder_shift = {remainder_q[XLEN-1:0], quotient_q[XLEN-1]};
        divisor_extended = $signed({1'b0, divisor_q});

        if (remainder_q[XLEN])
            remainder_next = remainder_shift + divisor_extended;
        else
            remainder_next = remainder_shift - divisor_extended;

        quotient_next = {quotient_q[XLEN-2:0], ~remainder_next[XLEN]};
        if (remainder_next[XLEN])
            remainder_corrected = remainder_next + divisor_extended;
        else
            remainder_corrected = remainder_next;

        next_state = curr_state;
        quotient_d = quotient_q;
        remainder_d = remainder_q;
        divisor_d = divisor_q;
        iteration_d = iteration_q;
        quotient_negative_d = quotient_negative_q;
        remainder_negative_d = remainder_negative_q;
        is_remainder_d = is_remainder_q;
        div_result_d = div_result;

        case (curr_state)
            IDLE: begin
                if (start) begin
                    if (is_signed && operand_a[XLEN-1])
                        quotient_d = (~operand_a) + 1'b1;
                    else
                        quotient_d = operand_a;

                    if (is_signed && operand_b[XLEN-1])
                        divisor_d = (~operand_b) + 1'b1;
                    else
                        divisor_d = operand_b;

                    remainder_d = '0;
                    iteration_d = '0;
                    quotient_negative_d = is_signed &&
                                          (operand_a[XLEN-1] ^ operand_b[XLEN-1]);
                    remainder_negative_d = is_signed && operand_a[XLEN-1];
                    is_remainder_d = (m_opcode == M_REM) ||
                                     (m_opcode == M_REMU);

                    if (!valid_opcode) begin
                        div_result_d = '0;
                        next_state = COMPLETE;
                    end else if (operand_b == '0) begin
                        if (is_remainder_d)
                            div_result_d = operand_a;
                        else
                            div_result_d = {XLEN{1'b1}};
                        next_state = COMPLETE;
                    end else if (is_signed &&
                                 (operand_a == {1'b1, {(XLEN-1){1'b0}}}) &&
                                 (operand_b == {XLEN{1'b1}})) begin
                        if (is_remainder_d)
                            div_result_d = '0;
                        else
                            div_result_d = {1'b1, {(XLEN-1){1'b0}}};
                        next_state = COMPLETE;
                    end else begin
                        next_state = ITERATE;
                    end
                end
            end

            ITERATE: begin
                quotient_d = quotient_next;
                remainder_d = remainder_next;

                if (iteration_q == XLEN-1) begin
                    if (is_remainder_q) begin
                        if (remainder_negative_q)
                            div_result_d = (~remainder_corrected[XLEN-1:0]) + 1'b1;
                        else
                            div_result_d = remainder_corrected[XLEN-1:0];
                    end else if (quotient_negative_q) begin
                        div_result_d = (~quotient_next) + 1'b1;
                    end else begin
                        div_result_d = quotient_next;
                    end
                    next_state = COMPLETE;
                end else begin
                    iteration_d = iteration_q + 1'b1;
                end
            end

            COMPLETE: next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin : DIVIDER_REG
        if (!rst_n) begin
            curr_state              <= IDLE;
            quotient_q              <= '0;
            remainder_q             <= '0;
            divisor_q               <= '0;
            iteration_q             <= '0;
            quotient_negative_q     <= 1'b0;
            remainder_negative_q    <= 1'b0;
            is_remainder_q          <= 1'b0;
            div_result              <= '0;
        end else begin
            curr_state              <= next_state;
            quotient_q              <= quotient_d;
            remainder_q             <= remainder_d;
            divisor_q               <= divisor_d;
            iteration_q             <= iteration_d;
            quotient_negative_q     <= quotient_negative_d;
            remainder_negative_q    <= remainder_negative_d;
            is_remainder_q          <= is_remainder_d;
            div_result              <= div_result_d;
        end
    end
endmodule
