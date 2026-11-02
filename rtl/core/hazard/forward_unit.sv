//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-15
// Design Name:
// Module Name: forward_unit
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the forward_unit module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module forward_unit (
    input  logic         mem_rd_wren, wb_rd_wren,
    input  logic         [REG_ADDR_WIDTH-1:0] ex_rs1_addr,
    input  logic         [REG_ADDR_WIDTH-1:0] ex_rs2_addr,
    input  logic         [REG_ADDR_WIDTH-1:0] mem_rd_addr,
    input  logic         [REG_ADDR_WIDTH-1:0] wb_rd_addr,
    output logic        fwd_a_mem,
    output logic        fwd_a_wb,
    output logic        fwd_b_mem,
    output logic        fwd_b_wb
);
    assign fwd_a_mem = mem_rd_wren && (mem_rd_addr != '0) &&
                       (mem_rd_addr == ex_rs1_addr);
    assign fwd_a_wb  = !fwd_a_mem && wb_rd_wren && (wb_rd_addr != '0) &&
                       (wb_rd_addr == ex_rs1_addr);

    assign fwd_b_mem = mem_rd_wren && (mem_rd_addr != '0) &&
                       (mem_rd_addr == ex_rs2_addr);
    assign fwd_b_wb  = !fwd_b_mem && wb_rd_wren && (wb_rd_addr != '0) &&
                       (wb_rd_addr == ex_rs2_addr);

endmodule
