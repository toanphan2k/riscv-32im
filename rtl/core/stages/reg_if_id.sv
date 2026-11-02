//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-03
// Design Name:
// Module Name: reg_if_id
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the reg_if_id module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module reg_if_id (
    input  logic                clk,
    input  logic                rst_n,
    input  logic                stall,
    input  logic                flush,
    // Inputs from IF stage
    input  logic [XLEN-1:0]     if_instr,
    input  logic [XLEN-1:0]     if_pc4,
    input  logic [XLEN-1:0]     if_pc,
    // Outputs to ID stage
    output logic [XLEN-1:0]     id_instr,
    output logic [XLEN-1:0]     id_pc4,
    output logic [XLEN-1:0]     id_pc
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            id_instr        <= NOP_INSTR;
            id_pc4          <= RST_32BIT_VECTOR;
            id_pc           <= RST_32BIT_VECTOR;
        end else if (!stall) begin
            id_instr        <= if_instr;
            id_pc4          <= if_pc4;
            id_pc           <= if_pc;
        end
    end

endmodule