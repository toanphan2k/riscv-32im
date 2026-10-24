//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Copilot
//
// Create Date: 2026-10-22
// Design Name:
// Module Name: tb_stage_id
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Simulation testbench for stage_id.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import rv32im_pkg::*;

module tb_stage_id;
    logic clk;
    logic rst_n;
    logic [XLEN-1:0] id_pc;
    logic [XLEN-1:0] id_pc4;
    logic [XLEN-1:0] id_instr;
    logic wb_en_reg_write;
    logic [XLEN-1:0] wb_data;
    logic [REG_ADDR_WIDTH-1:0] wb_rd_addr;

    ctrl_signal_t id_ctrl;
    logic [XLEN-1:0] id_imm;
    logic [XLEN-1:0] id_out_pc;
    logic [XLEN-1:0] id_out_pc4;
    logic [XLEN-1:0] id_rs1_data;
    logic [XLEN-1:0] id_rs2_data;
    logic [REG_ADDR_WIDTH-1:0] id_rs1_addr;
    logic [REG_ADDR_WIDTH-1:0] id_rs2_addr;
    logic [REG_ADDR_WIDTH-1:0] id_rd_addr;

    int tests = 0;
    int passed = 0;
    int failed = 0;

    stage_id dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .id_pc           (id_pc),
        .id_pc4          (id_pc4),
        .id_instr        (id_instr),
        .wb_en_reg_write (wb_en_reg_write),
        .wb_data         (wb_data),
        .wb_rd_addr      (wb_rd_addr),
        .id_ctrl         (id_ctrl),
        .id_imm          (id_imm),
        .id_out_pc       (id_out_pc),
        .id_out_pc4      (id_out_pc4),
        .id_rs1_data     (id_rs1_data),
        .id_rs2_data     (id_rs2_data),
        .id_rs1_addr     (id_rs1_addr),
        .id_rs2_addr     (id_rs2_addr),
        .id_rd_addr      (id_rd_addr)
    );

    always #5 clk = ~clk;

    function automatic logic [XLEN-1:0] encode_i(
        input logic [11:0] imm,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        encode_i = {imm, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [XLEN-1:0] encode_r(
        input logic [6:0] opcode,
        input logic [4:0] rd,
        input logic [2:0] funct3,
        input logic [4:0] rs1,
        input logic [4:0] rs2,
        input logic [6:0] funct7
    );
        encode_r = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [XLEN-1:0] encode_s(
        input logic [11:0] imm,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [6:0] opcode
    );
        encode_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction

    function automatic logic [XLEN-1:0] encode_b(
        input logic [12:0] imm,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [6:0] opcode
    );
        encode_b = {imm[12], imm[10:5], rs2, rs1, funct3,
                    imm[4:1], imm[11], opcode};
    endfunction

    task automatic record_result(input string name, input logic ok);
        begin
            tests++;
            if (ok === 1'b1) begin
                passed++;
                $display("[PASS] %s", name);
            end else begin
                failed++;
                $display("[FAIL] %s", name);
            end
        end
    endtask

    task automatic check_decode(
        input string name,
        input logic [XLEN-1:0] instr,
        input logic [REG_ADDR_WIDTH-1:0] exp_rs1,
        input logic [REG_ADDR_WIDTH-1:0] exp_rs2,
        input logic [REG_ADDR_WIDTH-1:0] exp_rd,
        input logic [XLEN-1:0] exp_imm,
        input logic exp_uses_rs1,
        input logic exp_uses_rs2,
        input logic exp_reg_write,
        input logic exp_mem_read,
        input logic exp_mem_write,
        input logic exp_branch,
        input logic exp_jump,
        input wb_src_sel_e exp_wb_src_sel
    );
        logic ok;
        begin
            id_instr = instr;
            #1;
            ok = (id_rs1_addr === exp_rs1) &&
                 (id_rs2_addr === exp_rs2) &&
                 (id_rd_addr === exp_rd) &&
                 (id_imm === exp_imm) &&
                 (id_ctrl.uses_rs1 === exp_uses_rs1) &&
                 (id_ctrl.uses_rs2 === exp_uses_rs2) &&
                 (id_ctrl.en_reg_write === exp_reg_write) &&
                 (id_ctrl.en_mem_read === exp_mem_read) &&
                 (id_ctrl.en_mem_write === exp_mem_write) &&
                 (id_ctrl.en_branch === exp_branch) &&
                 (id_ctrl.en_jump === exp_jump) &&
                 (id_ctrl.wb_src_sel === exp_wb_src_sel);
            record_result(name, ok);
            if (!ok) begin
                $display("       rs1=%0d/%0d rs2=%0d/%0d rd=%0d/%0d imm=%h/%h",
                         id_rs1_addr, exp_rs1, id_rs2_addr, exp_rs2,
                         id_rd_addr, exp_rd, id_imm, exp_imm);
                $display("       uses=%b%b expected=%b%b regwr=%b memrd=%b memwr=%b branch=%b jump=%b",
                         id_ctrl.uses_rs1, id_ctrl.uses_rs2,
                         exp_uses_rs1, exp_uses_rs2, id_ctrl.en_reg_write,
                         id_ctrl.en_mem_read, id_ctrl.en_mem_write,
                         id_ctrl.en_branch, id_ctrl.en_jump);
                $display("       wb_src_sel=%b expected=%b",
                         id_ctrl.wb_src_sel, exp_wb_src_sel);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        id_pc = '0;
        id_pc4 = '0;
        id_instr = NOP_INSTR;
        wb_en_reg_write = 1'b0;
        wb_data = '0;
        wb_rd_addr = '0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        $display("===== stage_id testbench start =====");

        id_pc = 32'h1000;
        id_pc4 = 32'h1004;
        check_decode("PC and PC+4 pass through",
                     encode_i(12'd7, 5'd3, ADD, 5'd4, OP_IMM),
                     5'd3, 5'd7, 5'd4, 32'd7,
                     1, 0, 1, 0, 0, 0, 0, WB_SRC_ALU);
        record_result("PC outputs match inputs",
                      id_out_pc === 32'h1000 && id_out_pc4 === 32'h1004);

        check_decode("ADDI positive immediate and source decode",
                     encode_i(12'd123, 5'd3, ADD, 5'd4, OP_IMM),
                     5'd3, 5'd27, 5'd4, 32'd123,
                     1, 0, 1, 0, 0, 0, 0, WB_SRC_ALU);
        check_decode("ADDI sign-extends negative immediate",
                     encode_i(12'hFFD, 5'd3, ADD, 5'd4, OP_IMM),
                     5'd3, 5'd29, 5'd4, 32'hFFFF_FFFD,
                     1, 0, 1, 0, 0, 0, 0, WB_SRC_ALU);
        check_decode("LW decodes base register and signed offset",
                     encode_i(12'hFF8, 5'd6, LD_LW, 5'd7, OP_LOAD),
                     5'd6, 5'd24, 5'd7, 32'hFFFF_FFF8,
                     1, 0, 1, 1, 0, 0, 0, WB_SRC_MEM);
        check_decode("JALR decodes register, immediate, and jump",
                     encode_i(12'd12, 5'd8, ADD, 5'd1, OP_JALR),
                     5'd8, 5'd12, 5'd1, 32'd12,
                     1, 0, 1, 0, 0, 0, 1, WB_SRC_PC_4);
        check_decode("SW decodes both sources and split immediate",
                     encode_s(12'hFE4, 5'd10, 5'd9, ST_SW, OP_STORE),
                     5'd9, 5'd10, 5'd4, 32'hFFFF_FFE4,
                     1, 1, 0, 0, 1, 0, 0, WB_SRC_ALU);
        check_decode("BEQ decodes both sources and branch immediate",
                     encode_b(13'd16, 5'd12, 5'd11, BR_BEQ, OP_BRANCH),
                     5'd11, 5'd12, 5'd16, 32'd16,
                     1, 1, 0, 0, 0, 1, 0, WB_SRC_ALU);
        check_decode("LUI does not use source registers",
                     32'h1234_52B7, 5'd8, 5'd3, 5'd5, 32'h1234_5000,
                     0, 0, 1, 0, 0, 0, 0, WB_SRC_ALU);
        check_decode("AUIPC does not use source registers",
                     32'h0001_0717, 5'd2, 5'd0, 5'd14, 32'h0001_0000,
                     0, 0, 1, 0, 0, 0, 0, WB_SRC_ALU);
        check_decode("JAL decodes jump and UJ immediate",
                     32'h0100_00EF, 5'd0, 5'd16, 5'd1, 32'd16,
                     0, 0, 1, 0, 0, 0, 1, WB_SRC_PC_4);
        check_decode("R-type instruction uses both operands",
                     encode_r(OP_REG, 5'd3, ADD, 5'd1, 5'd2, 7'b0000000),
                     5'd1, 5'd2, 5'd3, 32'd0,
                     1, 1, 1, 0, 0, 0, 0, WB_SRC_ALU);
        record_result("R-type ADD selects ALU_ADD",
                      id_ctrl.alu_opcode === ALU_ADD);
        check_decode("R-type SUB uses both operands",
                     encode_r(OP_REG, 5'd4, ADD, 5'd3, 5'd1, 7'b0100000),
                     5'd3, 5'd1, 5'd4, 32'd0,
                     1, 1, 1, 0, 0, 0, 0, WB_SRC_ALU);
        record_result("R-type SUB selects ALU_SUB",
                      id_ctrl.alu_opcode === ALU_SUB);
        check_decode("M-extension instruction decodes M control",
                     {7'b0000001, 5'd2, 5'd1, M_DIV, 5'd3, OP_REG},
                     5'd1, 5'd2, 5'd3, 32'd0,
                     1, 1, 1, 0, 0, 0, 0, WB_SRC_M_EXT);

        wb_en_reg_write = 1'b1;
        wb_rd_addr = 5'd5;
        wb_data = 32'hCAFE_BABE;
        id_instr = encode_i(12'd0, 5'd5, ADD, 5'd6, OP_IMM);
        #1;
        record_result("writeback bypasses to rs1",
                      id_rs1_data === 32'hCAFE_BABE);
        @(posedge clk);
        #1;
        wb_en_reg_write = 1'b0;
        id_instr = encode_i(12'd0, 5'd5, ADD, 5'd6, OP_IMM);
        #1;
        record_result("register file retains written value",
                      id_rs1_data === 32'hCAFE_BABE);

        wb_en_reg_write = 1'b1;
        wb_rd_addr = 5'd0;
        wb_data = 32'hFFFF_FFFF;
        id_instr = encode_i(12'd0, 5'd0, ADD, 5'd6, OP_IMM);
        #1;
        record_result("x0 reads as zero and ignores writeback",
                      id_rs1_data === 32'd0);
        @(posedge clk);
        #1;
        wb_en_reg_write = 1'b0;

        $display("===== stage_id SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 tests, passed, failed);
        if (failed == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: TESTS FAILED");
        $display("============================");
        if (failed != 0) $fatal(1, "stage_id: %0d test(s) failed", failed);
        $finish;
    end
endmodule
