//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-12
// Design Name:
// Module Name: register_file
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the register_file module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module register_file #(
    parameter logic [XLEN-1:0] RESET_SP = '0
) (
    input  logic clk,
    input  logic rst_n,

    input  logic [REG_ADDR_WIDTH-1:0]   raddr1,
    output logic [XLEN-1:0]             rdata1,

    input  logic [REG_ADDR_WIDTH-1:0]   raddr2,
    output logic [XLEN-1:0]             rdata2,

    input  logic en_write,
    input  logic [REG_ADDR_WIDTH-1:0]   waddr,
    input  logic [XLEN-1:0]             wdata
);

    logic [XLEN-1:0] regs[0:REG_NUM-1];

    // Synchronous write data
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin: WRITE_REG_DATA
        if(!rst_n) begin
            // Initialize all registers to 0
            // x2 is the stack pointer, initialize it to RESET_SP
            // init x2 point to 0x4000, not yet in dmem space
            // 0x4000 = 16384 = 1 << 14;
            // last byte address in dmem = 0x3FFF, 16383
            for (i = 0; i < REG_NUM; i = i + 1) begin
                regs[i] <= (i == 2) ? RESET_SP : {XLEN{1'b0}};
            end
        end else begin
            if (en_write && (waddr != 5'b0)) begin
                regs[waddr] <= wdata;
            end
        end
    end

    // Asynchronous read
    always_comb begin : READ_REG1_DATA
        if (raddr1 == 5'b0) begin
            rdata1 = {XLEN{1'b0}};
        end else if ((en_write && (waddr == raddr1))) begin
            rdata1 = wdata;
        end else begin
            rdata1 = regs[raddr1];
        end
    end

    always_comb begin : READ_REG2_DATA
        if (raddr2 == 5'b0) begin
            rdata2 = {XLEN{1'b0}};
        end else if ((en_write && (waddr == raddr2))) begin
            rdata2 = wdata;
        end else begin
            rdata2 = regs[raddr2];
        end
    end

endmodule
