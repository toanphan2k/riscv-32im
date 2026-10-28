//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-09-28
// Design Name:
// Module Name: stage_id
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the stage_id module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module stage_id #(
    parameter logic [XLEN-1:0] RESET_SP = '0
) (
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic [XLEN-1:0]             id_pc,
    input  logic [XLEN-1:0]             id_pc4,
    input  logic [XLEN-1:0]             id_instr,
    // Writeback port from WB stage
    input  logic                        wb_en_reg_write,
    input  logic [XLEN-1:0]             wb_data,
    input  logic [REG_ADDR_WIDTH-1:0]   wb_rd_addr,
    // Ouput signals to ID/EX Register
    output ctrl_signal_t                id_ctrl,
    output logic [XLEN-1:0]             id_imm,
    output logic [XLEN-1:0]             id_out_pc,
    output logic [XLEN-1:0]             id_out_pc4,
    output logic [XLEN-1:0]             id_rs1_data,
    output logic [XLEN-1:0]             id_rs2_data,
    output logic [REG_ADDR_WIDTH-1:0]   id_rs1_addr,
    output logic [REG_ADDR_WIDTH-1:0]   id_rs2_addr,
    output logic [REG_ADDR_WIDTH-1:0]   id_rd_addr
);

    assign id_out_pc  = id_pc;
    assign id_out_pc4 = id_pc4;

    id_decoder_ctrl id_decoder_ctrl_u(
        .instr(id_instr),
        .ctrl(id_ctrl),
        .rs1_addr(id_rs1_addr),
        .rs2_addr(id_rs2_addr),
        .rd_addr(id_rd_addr)
    );

    id_imm_gen id_imm_gen_u (
        .instr(id_instr),
        .imm(id_imm)
    );

    register_file #(
        .RESET_SP(RESET_SP)
    ) register_file_u (
        .clk(clk),
        .rst_n(rst_n),
        .raddr1(id_rs1_addr),
        .rdata1(id_rs1_data),
        .raddr2(id_rs2_addr),
        .rdata2(id_rs2_data),
        .en_write(wb_en_reg_write),
        .waddr(wb_rd_addr),
        .wdata(wb_data)
    );

endmodule
