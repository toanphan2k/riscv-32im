//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-12
// Design Name:
// Module Name: m_extesion_unit
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the m_extesion_unit module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module m_extesion_unit(
    input  logic            clk,
    input  logic            rst_n,
    input  logic            start,
    input  m_ext_opcode_e   m_opcode,
    input  logic [XLEN-1:0] operand_a,
    input  logic [XLEN-1:0] operand_b,
    output logic [XLEN-1:0] m_result,
    output logic            is_busy,
    output logic            done
);

    logic is_mul;
    logic is_div;

    logic is_mul_q;

    logic mul_start;
    logic mul_done;
    logic mul_busy;

    logic div_start;
    logic div_done;
    logic div_busy;

    logic units_idle;

    logic [XLEN-1:0] mul_result;
    logic [XLEN-1:0] div_result;

    assign is_mul = (m_opcode == M_MUL) ||
                    (m_opcode == M_MULH) ||
                    (m_opcode == M_MULHSU) ||
                    (m_opcode == M_MULHU);
    assign is_div = (m_opcode == M_DIV) ||
                    (m_opcode == M_DIVU) ||
                    (m_opcode == M_REM) ||
                    (m_opcode == M_REMU);

    assign units_idle = !(mul_busy || div_busy || mul_done || div_done);
    assign mul_start = start && is_mul && units_idle;
    assign div_start = start && is_div && units_idle;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            is_mul_q <= 1'b1;
        else if (mul_start || div_start)
            is_mul_q <= is_mul;
    end

    //-----------------------------------------------
    // BEGIN CODE BLOCK FOR SIMPLE M UNITS USING DSP
    // SORRY: Just figure out, on FPGA DIV and REM not using DSP
    // DSP only support MUL
    //-----------------------------------------------
    /*
    simple_multiplier multiplier_u (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .m_opcode(m_opcode),
        .mul_result(mul_result)
    );
    */

    /*
    simple_divider divider_u (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .m_opcode(m_opcode),
        .div_result(div_result)
    );
    // temp logic since simple divider is combinational logic
    // and do not have have start and odne
    assign div_start    = 1'b0;
    assign div_done     = 1'b1;
    */
    //-----------------------------------------------
    // END CODE BLOCK FOR SIMPLE M UNITS USING DSP
    // SORRY: Just figure out, on FPGA DIV and REM not using DSP
    //-----------------------------------------------

    //-----------------------------------------------
    // BEGIN CODE BLOCK FOR Verdic_32bit_multiplier
    //-----------------------------------------------
    verdic_32bit_multiplier_seq multiplier_u (
        .clk(clk),
        .rst_n(rst_n),
        .start(mul_start),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .m_opcode(m_opcode),
        .mul_result(mul_result),
        .is_busy(mul_busy),
        .done(mul_done)
    );
    //-----------------------------------------------
    // END CODE BLOCK FOR Verdic_32bit_multiplier
    //-----------------------------------------------

    //-----------------------------------------------
    // BEGIN CODE BLOCK FOR OHER RADIX4-NONRES
    //-----------------------------------------------
    radix2_res_divider divider_u (
        .clk(clk),
        .rst_n(rst_n),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .m_opcode(m_opcode),
        .div_result(div_result),
        .start(div_start),
        .done(div_done),
        .is_busy(div_busy)
    );

    //-----------------------------------------------
    // END CODE BLOCK FOR OHER RADIX4-NONRES
    //-----------------------------------------------

    // General Pipeline signals
    /*
    assign done     = is_mul ? 1'b1 : div_done;
    assign m_result = is_div ? div_result : mul_result;
    */
    assign is_busy = mul_start || div_start || mul_busy || div_busy;
    assign done = mul_done || div_done;
    assign m_result = is_mul_q ? mul_result : div_result;

endmodule
