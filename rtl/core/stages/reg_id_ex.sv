//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-03
// Design Name:
// Module Name: reg_id_ex
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the reg_id_ex module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module reg_id_ex (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    stall,
    input  logic                    flush,
    // Inputs from ID stage
    input  ctrl_signal_t            id_ctrl,
    input  logic [XLEN-1:0]         id_pc,
    input  logic [XLEN-1:0]         id_pc4,
    input  logic [XLEN-1:0]         id_imm,
    input  logic [XLEN-1:0]         id_rs1_data,
    input  logic [XLEN-1:0]         id_rs2_data,
    input  logic [REG_ADDR_WIDTH-1:0]    id_rs1_addr,
    input  logic [REG_ADDR_WIDTH-1:0]    id_rs2_addr,
    input  logic [REG_ADDR_WIDTH-1:0]    id_rd_addr,
    // Outputs to EX stage
    output ctrl_signal_t            ex_ctrl,
    output logic [XLEN-1:0]         ex_pc,
    output logic [XLEN-1:0]         ex_pc4,
    output logic [XLEN-1:0]         ex_imm,
    output logic [XLEN-1:0]         ex_rs1_data,
    output logic [XLEN-1:0]         ex_rs2_data,
    output logic [REG_ADDR_WIDTH-1:0]    ex_rs1_addr,
    output logic [REG_ADDR_WIDTH-1:0]    ex_rs2_addr,
    output logic [REG_ADDR_WIDTH-1:0]    ex_rd_addr
);

    ctrl_signal_t nop_ctrl;
    assign nop_ctrl = '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            ex_ctrl             <= nop_ctrl;
            ex_pc               <= RST_32BIT_VECTOR;
            ex_pc4              <= RST_32BIT_VECTOR;
            ex_imm              <= RST_32BIT_VECTOR;
            ex_rs1_data         <= RST_32BIT_VECTOR;
            ex_rs2_data         <= RST_32BIT_VECTOR;
            ex_rs1_addr         <= 5'b0;
            ex_rs2_addr         <= 5'b0;
            ex_rd_addr          <= 5'b0;
        end else if (!stall) begin
            ex_ctrl             <= id_ctrl;
            ex_pc               <= id_pc;
            ex_pc4              <= id_pc4;
            ex_imm              <= id_imm;
            ex_rs1_data         <= id_rs1_data;
            ex_rs2_data         <= id_rs2_data;
            ex_rs1_addr         <= id_rs1_addr;
            ex_rs2_addr         <= id_rs2_addr;
            ex_rd_addr          <= id_rd_addr;
        end
    end

endmodule
