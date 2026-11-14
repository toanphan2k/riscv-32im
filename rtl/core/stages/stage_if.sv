//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-09-28
// Design Name:
// Module Name: stage_if
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the stage_if module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module stage_if (
    input  logic clk,
    input  logic rst_n,

    input  logic pc_en,
    input  logic pc_src_sel,
    input  logic [XLEN-1:0] branch_target_addr,

    output logic [XLEN-1:0] pc,
    output logic [XLEN-1:0] pc4,

    output logic            is_fetch_valid,
    output logic [XLEN-1:0] imem_addr,
    output logic            imem_read_req
);

    logic [31:0] pc_q;
    logic [31:0] next_pc;
    logic        is_fetch_valid_q;
    logic        advance;

    assign pc4 = pc_q + 32'd4;
    assign next_pc = pc_src_sel ? branch_target_addr : pc4;

    assign advance = is_fetch_valid_q && pc_en;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pc_q <= RST_32BIT_VECTOR;
            is_fetch_valid_q <= 1'b0;
        end else begin
            is_fetch_valid_q <= 1'b1;
            if (advance) pc_q <= next_pc;
        end
    end

    assign pc = pc_q;
    assign is_fetch_valid = is_fetch_valid_q;
    assign imem_addr = advance ? next_pc : pc_q;
    assign imem_read_req = 1'b1;
endmodule
