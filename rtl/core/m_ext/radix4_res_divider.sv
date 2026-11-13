//////////////////////////////////////////////////////////////////////////////////
// Iterative radix-4 restoring divider for the RV32M extension.
// Each cycle performs two radix-2 restoring steps.
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module radix4_res_divider(
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
    localparam integer RADIX4_ITERATIONS = XLEN / 2;
    localparam integer COUNT_WIDTH = (RADIX4_ITERATIONS > 1) ?
                                     $clog2(RADIX4_ITERATIONS) : 1;

    typedef enum logic [1:0] {IDLE, ITERATE, COMPLETE} div_state_e;
    div_state_e curr_state, next_state;

    logic [XLEN-1:0] quotient_q, quotient_d;
    logic [XLEN-1:0] quotient_step;
    logic [XLEN:0] remainder_q, remainder_d;
    logic [XLEN+1:0] remainder_trial, remainder_step;
    logic [XLEN+1:0] divisor_extended, divisor_x2, divisor_x3;
    logic [1:0] quotient_digit;
    logic [XLEN-1:0] divisor_q, divisor_d;
    logic [COUNT_WIDTH-1:0] iteration_q, iteration_d;
    logic quotient_negative_q, quotient_negative_d;
    logic remainder_negative_q, remainder_negative_d;
    logic is_remainder_q, is_remainder_d;
    logic valid_opcode;
    logic [XLEN-1:0] div_result_d;
    logic is_signed;

    assign is_signed = (m_opcode == M_DIV) || (m_opcode == M_REM);
    assign valid_opcode = (m_opcode == M_DIV)  || (m_opcode == M_DIVU) ||
                          (m_opcode == M_REM)  || (m_opcode == M_REMU);
    assign is_busy = (curr_state == ITERATE);
    assign done = (curr_state == COMPLETE);

    always_comb begin
        divisor_extended = {{2{1'b0}}, divisor_q};
        divisor_x2 = divisor_extended << 1;
        divisor_x3 = divisor_x2 + divisor_extended;
        remainder_trial = {remainder_q[XLEN-1:0], quotient_q[XLEN-1:XLEN-2]};

        if (remainder_trial >= divisor_x3) begin
            quotient_digit = 2'd3;
            remainder_step = remainder_trial - divisor_x3;
        end else if (remainder_trial >= divisor_x2) begin
            quotient_digit = 2'd2;
            remainder_step = remainder_trial - divisor_x2;
        end else if (remainder_trial >= divisor_extended) begin
            quotient_digit = 2'd1;
            remainder_step = remainder_trial - divisor_extended;
        end else begin
            quotient_digit = 2'd0;
            remainder_step = remainder_trial;
        end
        quotient_step = (quotient_q << 2) | quotient_digit;

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
                    quotient_d = (is_signed && operand_a[XLEN-1]) ?
                                 (~operand_a + 1'b1) : operand_a;
                    divisor_d = (is_signed && operand_b[XLEN-1]) ?
                                (~operand_b + 1'b1) : operand_b;
                    remainder_d = '0;
                    iteration_d = '0;
                    quotient_negative_d = is_signed &&
                                          (operand_a[XLEN-1] ^ operand_b[XLEN-1]);
                    remainder_negative_d = is_signed && operand_a[XLEN-1];
                    is_remainder_d = (m_opcode == M_REM) || (m_opcode == M_REMU);

                    if (!valid_opcode) begin
                        div_result_d = '0;
                        next_state = COMPLETE;
                    end else if (operand_b == '0) begin
                        div_result_d = is_remainder_d ? operand_a : {XLEN{1'b1}};
                        next_state = COMPLETE;
                    end else if (is_signed &&
                                 (operand_a == {1'b1, {(XLEN-1){1'b0}}}) &&
                                 (operand_b == {XLEN{1'b1}})) begin
                        div_result_d = is_remainder_d ? '0 :
                                       {1'b1, {(XLEN-1){1'b0}}};
                        next_state = COMPLETE;
                    end else begin
                        next_state = ITERATE;
                    end
                end
            end

            ITERATE: begin
                quotient_d = quotient_step;
                remainder_d = remainder_step[XLEN:0];
                if (iteration_q == RADIX4_ITERATIONS-1) begin
                    if (is_remainder_q)
                        div_result_d = remainder_negative_q ?
                            (~remainder_step[XLEN-1:0] + 1'b1) :
                            remainder_step[XLEN-1:0];
                    else
                        div_result_d = quotient_negative_q ?
                            (~quotient_step + 1'b1) : quotient_step;
                    next_state = COMPLETE;
                end else begin
                    iteration_d = iteration_q + 1'b1;
                end
            end

            COMPLETE: next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state          <= IDLE;
            quotient_q          <= '0;
            remainder_q         <= '0;
            divisor_q           <= '0;
            iteration_q         <= '0;
            quotient_negative_q <= 1'b0;
            remainder_negative_q <= 1'b0;
            is_remainder_q      <= 1'b0;
            div_result          <= '0;
        end else begin
            curr_state          <= next_state;
            quotient_q          <= quotient_d;
            remainder_q         <= remainder_d;
            divisor_q           <= divisor_d;
            iteration_q         <= iteration_d;
            quotient_negative_q <= quotient_negative_d;
            remainder_negative_q <= remainder_negative_d;
            is_remainder_q      <= is_remainder_d;
            div_result          <= div_result_d;
        end
    end
endmodule
