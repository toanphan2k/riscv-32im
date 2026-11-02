//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-03
// Design Name:
// Module Name: reg_mem_wb
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the reg_mem_wb module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module reg_mem_wb (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    stall,
    input  logic                    flush,
    // Inputs from MEM stage
    input  ctrl_signal_t            mem_ctrl,
    input  logic [XLEN-1:0]         mem_alu_result,
    input  logic [XLEN-1:0]         mem_m_unit_result,
    input  logic [XLEN-1:0]         mem_pc4,
    input  logic [REG_ADDR_WIDTH-1:0]    mem_rd_addr,


    // Outputs to WB stage
    output ctrl_signal_t            wb_ctrl,
    output logic [XLEN-1:0]         wb_alu_result,
    output logic [XLEN-1:0]         wb_m_unit_result,
    output logic [XLEN-1:0]         wb_pc4,
    output logic [REG_ADDR_WIDTH-1:0]    wb_rd_addr
);

    ctrl_signal_t nop_ctrl;
    assign nop_ctrl = '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            wb_ctrl             <= nop_ctrl;
            wb_alu_result       <= RST_32BIT_VECTOR;
            wb_m_unit_result    <= RST_32BIT_VECTOR;
            wb_pc4              <= RST_32BIT_VECTOR;
            wb_rd_addr          <= 5'b0;
        end else if (!stall) begin
            wb_ctrl             <= mem_ctrl;
            wb_alu_result       <= mem_alu_result;
            wb_m_unit_result    <= mem_m_unit_result;
            wb_pc4              <= mem_pc4;
            wb_rd_addr          <= mem_rd_addr;
        end
    end

endmodule