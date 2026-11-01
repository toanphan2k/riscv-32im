//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-05
// Design Name:
// Module Name: radix8_divider
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the radix8_divider module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module radix8_divider(
    input  logic            clk,
    input  logic            rst_n,
    input  logic            start,
    input  logic [XLEN-1]   operand_a,
    input  logic [XLEN-1]   operand_b,
    input  m_ext_opcode_e   m_opcode,
    output logic [XLEN-1]   div_result,
    output logic            is_busy,
    output logic            done
);

endmodule
