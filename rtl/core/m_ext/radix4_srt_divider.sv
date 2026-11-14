//////////////////////////////////////////////////////////////////////////////////
// Iterative radix-4 non-restoring divider for the RV32M extension.
// Each cycle selects a signed quotient digit for two normalized dividend bits.
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module radix4_srt_divider(
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
    localparam integer MAX_RADIX4_ITERATIONS = XLEN;
    localparam integer COUNT_WIDTH = (MAX_RADIX4_ITERATIONS > 1) ?
                                     $clog2(MAX_RADIX4_ITERATIONS + 1) : 1;
    localparam integer SHIFT_WIDTH = (XLEN > 1) ? $clog2(XLEN) : 1;

    typedef enum logic [1:0] {IDLE, ITERATE, COMPLETE} div_state_e;
    div_state_e curr_state, next_state;

    logic [2*XLEN-1:0] dividend_q, dividend_d;
    logic signed [XLEN+3:0] quotient_q, quotient_d;
    logic signed [XLEN+3:0] quotient_step, quotient_corrected;
    logic signed [XLEN+3:0] remainder_q, remainder_d;
    logic signed [XLEN+3:0] remainder_trial, remainder_step;
    logic signed [XLEN+3:0] remainder_corrected, remainder_unscaled;
    logic signed [XLEN+3:0] twice_trial, divisor_extended;
    logic signed [XLEN+3:0] divisor_x2, divisor_x3;
    logic signed [2:0] quotient_digit;
    logic signed [XLEN+3:0] quotient_digit_extended;
    logic [XLEN-1:0] magnitude_a, magnitude_b, normalized_divisor;
    logic [2*XLEN-1:0] normalized_dividend;
    logic [XLEN-1:0] divisor_q, divisor_d;
    logic [COUNT_WIDTH-1:0] iteration_q, iteration_d;
    logic [COUNT_WIDTH-1:0] iteration_limit_q, iteration_limit_d;
    logic [SHIFT_WIDTH-1:0] normalization_shift_q, normalization_shift_d;
    logic quotient_negative_q, quotient_negative_d;
    logic remainder_negative_q, remainder_negative_d;
    logic is_remainder_q, is_remainder_d;
    logic valid_opcode;
    logic [XLEN-1:0] div_result_d;
    logic is_signed;
    integer normalization_shift;
    integer padding_bits;
    integer required_iterations;

    assign is_signed = (m_opcode == M_DIV) || (m_opcode == M_REM);
    assign valid_opcode = (m_opcode == M_DIV)  || (m_opcode == M_DIVU) ||
                          (m_opcode == M_REM)  || (m_opcode == M_REMU);
    assign is_busy = (curr_state == ITERATE);
    assign done = (curr_state == COMPLETE);

    always_comb begin
        magnitude_a = (is_signed && operand_a[XLEN-1]) ?
                      (~operand_a + 1'b1) : operand_a;
        magnitude_b = (is_signed && operand_b[XLEN-1]) ?
                      (~operand_b + 1'b1) : operand_b;
        normalization_shift = 0;
        for (integer bit_index = 0; bit_index < XLEN; bit_index = bit_index + 1) begin
            if (magnitude_b[bit_index])
                normalization_shift = XLEN - 1 - bit_index;
        end
        required_iterations = (XLEN + normalization_shift + 1) / 2;
        padding_bits = (2 * required_iterations) -
                       (XLEN + normalization_shift);
        normalized_divisor = magnitude_b << normalization_shift;
        normalized_dividend = {{XLEN{1'b0}}, magnitude_a} << (XLEN - padding_bits);

        divisor_extended = $signed({4'b0000, divisor_q});
        divisor_x2 = divisor_extended << 1;
        divisor_x3 = divisor_x2 + divisor_extended;
        remainder_trial = (remainder_q <<< 2) +
                          $signed({{(XLEN+2){1'b0}}, dividend_q[2*XLEN-1:2*XLEN-2]});
        twice_trial = remainder_trial <<< 1;

        if (twice_trial >= divisor_x3)
            quotient_digit = 3'sd2;
        else if (twice_trial >= divisor_extended)
            quotient_digit = 3'sd1;
        else if (twice_trial <= -divisor_x3)
            quotient_digit = -3'sd2;
        else if (twice_trial <= -divisor_extended)
            quotient_digit = -3'sd1;
        else
            quotient_digit = 3'sd0;

        case (quotient_digit)
            3'sd2:   remainder_step = remainder_trial - divisor_x2;
            3'sd1:   remainder_step = remainder_trial - divisor_extended;
            -3'sd1:  remainder_step = remainder_trial + divisor_extended;
            -3'sd2:  remainder_step = remainder_trial + divisor_x2;
            default: remainder_step = remainder_trial;
        endcase

        quotient_digit_extended = {{(XLEN+1){quotient_digit[2]}}, quotient_digit};
        quotient_step = (quotient_q <<< 2) + quotient_digit_extended;
        remainder_corrected = remainder_step[XLEN+3] ?
                              remainder_step + divisor_extended : remainder_step;
        quotient_corrected = remainder_step[XLEN+3] ?
                             quotient_step - 1'b1 : quotient_step;
        remainder_unscaled = remainder_corrected >>> normalization_shift_q;

        next_state = curr_state;
        dividend_d = dividend_q;
        quotient_d = quotient_q;
        remainder_d = remainder_q;
        divisor_d = divisor_q;
        iteration_d = iteration_q;
        iteration_limit_d = iteration_limit_q;
        normalization_shift_d = normalization_shift_q;
        quotient_negative_d = quotient_negative_q;
        remainder_negative_d = remainder_negative_q;
        is_remainder_d = is_remainder_q;
        div_result_d = div_result;

        case (curr_state)
            IDLE: begin
                if (start) begin
                    dividend_d = normalized_dividend;
                    divisor_d = normalized_divisor;
                    quotient_d = '0;
                    remainder_d = '0;
                    iteration_d = '0;
                    iteration_limit_d = required_iterations;
                    normalization_shift_d = normalization_shift;
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
                dividend_d = dividend_q << 2;
                quotient_d = quotient_step;
                remainder_d = remainder_step;
                if (iteration_q == iteration_limit_q - 1'b1) begin
                    if (is_remainder_q)
                        div_result_d = remainder_negative_q ?
                            (~remainder_unscaled[XLEN-1:0] + 1'b1) :
                            remainder_unscaled[XLEN-1:0];
                    else
                        div_result_d = quotient_negative_q ?
                            (~quotient_corrected[XLEN-1:0] + 1'b1) :
                            quotient_corrected[XLEN-1:0];
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
            curr_state            <= IDLE;
            dividend_q            <= '0;
            quotient_q            <= '0;
            remainder_q           <= '0;
            divisor_q             <= '0;
            iteration_q           <= '0;
            iteration_limit_q     <= '0;
            normalization_shift_q <= '0;
            quotient_negative_q   <= 1'b0;
            remainder_negative_q  <= 1'b0;
            is_remainder_q        <= 1'b0;
            div_result            <= '0;
        end else begin
            curr_state            <= next_state;
            dividend_q            <= dividend_d;
            quotient_q            <= quotient_d;
            remainder_q           <= remainder_d;
            divisor_q             <= divisor_d;
            iteration_q           <= iteration_d;
            iteration_limit_q     <= iteration_limit_d;
            normalization_shift_q <= normalization_shift_d;
            quotient_negative_q   <= quotient_negative_d;
            remainder_negative_q  <= remainder_negative_d;
            is_remainder_q        <= is_remainder_d;
            div_result            <= div_result_d;
        end
    end
endmodule
