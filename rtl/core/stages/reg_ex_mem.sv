//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-02
// Design Name:
// Module Name: reg_ex_mem
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the reg_ex_mem module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module reg_ex_mem (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    stall,
    input  logic                    flush,
    // Inputs from EX stage
    input  ctrl_signal_t            ex_ctrl,
    input  logic [XLEN-1:0]         ex_pc4,
    input  logic [XLEN-1:0]         ex_alu_result,
    input  logic [XLEN-1:0]         ex_m_unit_result,
    input  logic [XLEN-1:0]         ex_rs2_data,
    input  logic [REG_ADDR_WIDTH-1:0]    ex_rd_addr,
    // Outputs to MEM stage
    output ctrl_signal_t            mem_ctrl,
    output logic [XLEN-1:0]         mem_pc4,
    output logic [XLEN-1:0]         mem_alu_result,
    output logic [XLEN-1:0]         mem_m_unit_result,
    output logic [XLEN-1:0]         mem_rs2_data,
    output logic [REG_ADDR_WIDTH-1:0]    mem_rd_addr
);

    ctrl_signal_t nop_ctrl;
    assign nop_ctrl = '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            mem_ctrl            <= nop_ctrl;
            mem_pc4             <= RST_32BIT_VECTOR;
            mem_alu_result      <= RST_32BIT_VECTOR;
            mem_m_unit_result   <= RST_32BIT_VECTOR;
            mem_rs2_data        <= RST_32BIT_VECTOR;
            mem_rd_addr         <= 4'b0;
        end else if (!stall) begin
            mem_ctrl            <= ex_ctrl;
            mem_pc4             <= ex_pc4;
            mem_alu_result      <= ex_alu_result;
            mem_m_unit_result   <= ex_m_unit_result;
            mem_rs2_data        <= ex_rs2_data;
            mem_rd_addr         <= ex_rd_addr;
        end
    end

endmodule
