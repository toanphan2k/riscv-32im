//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Copilot
//
// Create Date: 2026-10-22
// Design Name:
// Module Name: tb_stage_ex
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Simulation testbench for stage_ex.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import rv32im_pkg::*;

module tb_stage_ex;
    logic clk;
    logic rst_n;
    ctrl_signal_t ex_in_ctrl;
    logic [XLEN-1:0] ex_pc;
    logic [XLEN-1:0] ex_pc4;
    logic [XLEN-1:0] ex_rs1_data;
    logic [XLEN-1:0] ex_rs2_data;
    logic [XLEN-1:0] ex_imm;
    logic [REG_ADDR_WIDTH-1:0] ex_rd_addr;
    logic sel_a_mem;
    logic sel_a_wb;
    logic sel_b_mem;
    logic sel_b_wb;
    logic [XLEN-1:0] fwd_mem_data;
    logic [XLEN-1:0] fwd_wb_data;

    ctrl_signal_t ex_out_ctrl;
    logic [XLEN-1:0] ex_out_pc4;
    logic [XLEN-1:0] ex_out_alu_result;
    logic [XLEN-1:0] ex_out_m_unit_result;
    logic [XLEN-1:0] ex_out_rs2_data;
    logic [REG_ADDR_WIDTH-1:0] ex_out_rd_addr;
    logic branch_taken;
    logic [XLEN-1:0] branch_target_addr;
    logic m_unit_busy;

    int tests = 0;
    int passed = 0;
    int failed = 0;

    stage_ex dut (
        .clk                 (clk),
        .rst_n               (rst_n),
        .ex_in_ctrl          (ex_in_ctrl),
        .ex_pc               (ex_pc),
        .ex_pc4              (ex_pc4),
        .ex_rs1_data         (ex_rs1_data),
        .ex_rs2_data         (ex_rs2_data),
        .ex_imm              (ex_imm),
        .ex_rd_addr          (ex_rd_addr),
        .sel_a_mem           (sel_a_mem),
        .sel_a_wb            (sel_a_wb),
        .sel_b_mem           (sel_b_mem),
        .sel_b_wb            (sel_b_wb),
        .fwd_mem_data        (fwd_mem_data),
        .fwd_wb_data         (fwd_wb_data),
        .ex_out_ctrl         (ex_out_ctrl),
        .ex_out_pc4          (ex_out_pc4),
        .ex_out_alu_result   (ex_out_alu_result),
        .ex_out_m_unit_result(ex_out_m_unit_result),
        .ex_out_rs2_data     (ex_out_rs2_data),
        .ex_out_rd_addr      (ex_out_rd_addr),
        .branch_taken        (branch_taken),
        .branch_target_addr  (branch_target_addr),
        .m_unit_busy         (m_unit_busy)
    );

    always #5 clk = ~clk;

    task automatic run_case(
        input string name,
        input ctrl_signal_t ctrl,
        input logic [XLEN-1:0] pc,
        input logic [XLEN-1:0] pc4,
        input logic [XLEN-1:0] rs1,
        input logic [XLEN-1:0] rs2,
        input logic [XLEN-1:0] imm,
        input logic [REG_ADDR_WIDTH-1:0] rd,
        input fwd_sel_e forward_a,
        input fwd_sel_e forward_b,
        input logic [XLEN-1:0] mem_data,
        input logic [XLEN-1:0] wb_data,
        input logic [XLEN-1:0] expected_alu,
        input logic check_m_result,
        input logic [XLEN-1:0] expected_m_result,
        input logic [XLEN-1:0] expected_rs2,
        input logic expected_branch_taken,
        input logic [XLEN-1:0] expected_branch_target
    );
        logic case_passed;
        integer cycles;
        begin
            @(negedge clk);
            ex_in_ctrl   = ctrl;
            ex_pc        = pc;
            ex_pc4       = pc4;
            ex_rs1_data  = rs1;
            ex_rs2_data  = rs2;
            ex_imm       = imm;
            ex_rd_addr   = rd;
            sel_a_mem    = (forward_a == FWD_MEM);
            sel_a_wb     = (forward_a == FWD_WB);
            sel_b_mem    = (forward_b == FWD_MEM);
            sel_b_wb     = (forward_b == FWD_WB);
            fwd_mem_data = mem_data;
            fwd_wb_data  = wb_data;
            #1;

            case_passed = (m_unit_busy === ctrl.en_m_ext);
            cycles = 0;
            if (ctrl.en_m_ext) begin
                while ((m_unit_busy !== 1'b0) && (cycles < XLEN + 4)) begin
                    @(posedge clk);
                    #1;
                    cycles++;
                end
            end

            tests++;
            case_passed = case_passed && (ex_out_ctrl === ctrl) &&
                          (ex_out_pc4 === pc4) &&
                          (ex_out_rd_addr === rd) &&
                          (ex_out_alu_result === expected_alu) &&
                          (ex_out_rs2_data === expected_rs2) &&
                          (branch_taken === expected_branch_taken) &&
                          (branch_target_addr === expected_branch_target) &&
                          (m_unit_busy === 1'b0);
            if (check_m_result)
                case_passed = case_passed &&
                              (ex_out_m_unit_result === expected_m_result);

            if (case_passed) begin
                passed++;
                $display("[PASS] %s", name);
            end else begin
                failed++;
                $display("[FAIL] %s", name);
                $display("       ALU got=%h expected=%h | rs2 got=%h expected=%h",
                         ex_out_alu_result, expected_alu,
                         ex_out_rs2_data, expected_rs2);
                $display("       branch got=%b expected=%b | target got=%h expected=%h",
                         branch_taken, expected_branch_taken,
                         branch_target_addr, expected_branch_target);
                $display("       ctrl_match=%b pc4_match=%b rd_match=%b busy=%b",
                         ex_out_ctrl === ctrl, ex_out_pc4 === pc4,
                         ex_out_rd_addr === rd, m_unit_busy);
                if (check_m_result)
                    $display("       M result got=%h expected=%h",
                             ex_out_m_unit_result, expected_m_result);
            end

            if (ctrl.en_m_ext) begin
                @(negedge clk);
                ex_in_ctrl.en_m_ext = 1'b0;
                @(posedge clk);
                #1;
            end
        end
    endtask

    task automatic init_ctrl;
        begin
            ex_in_ctrl = '0;
            ex_in_ctrl.alu_src_a_sel = ALU_SRC_A_RS1;
            ex_in_ctrl.alu_src_b_sel = ALU_SRC_B_RS2;
            ex_in_ctrl.alu_opcode = ALU_ADD;
            ex_in_ctrl.m_ext_opcode = M_MUL;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        init_ctrl();
        ex_pc = '0;
        ex_pc4 = '0;
        ex_rs1_data = '0;
        ex_rs2_data = '0;
        ex_imm = '0;
        ex_rd_addr = '0;
        sel_a_mem = 1'b0;
        sel_a_wb  = 1'b0;
        sel_b_mem = 1'b0;
        sel_b_wb  = 1'b0;
        fwd_mem_data = '0;
        fwd_wb_data = '0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        $display("===== stage_ex testbench start =====");

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        run_case("register operands add", ex_in_ctrl, 32'h1000, 32'h1004,
                 32'd12, 32'd30, 32'd5, 5'd6, FWD_NONE, FWD_NONE,
                 32'd0, 32'd0, 32'd42, 0, '0, 32'd30, 0, 32'h1005);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        run_case("MEM forwards rs1", ex_in_ctrl, 32'h1000, 32'h1004,
                 32'd12, 32'd5, 32'd0, 5'd7, FWD_MEM, FWD_NONE,
                 32'd40, 32'd90, 32'd45, 0, '0, 32'd5, 0, 32'h1000);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        run_case("WB forwards rs2", ex_in_ctrl, 32'h1000, 32'h1004,
                 32'd7, 32'd5, 32'd0, 5'd8, FWD_NONE, FWD_WB,
                 32'd40, 32'd8, 32'd15, 0, '0, 32'd8, 0, 32'h1000);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        ex_in_ctrl.alu_src_b_sel = ALU_SRC_B_IMM;
        run_case("immediate selected for ALU operand B", ex_in_ctrl,
                 32'h1000, 32'h1004, 32'd7, 32'd100, 32'd5, 5'd9,
                 FWD_NONE, FWD_NONE, 32'd0, 32'd0, 32'd12, 0, '0,
                 32'd100, 0, 32'h1005);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        ex_in_ctrl.alu_src_a_sel = ALU_SRC_A_PC;
        ex_in_ctrl.alu_src_b_sel = ALU_SRC_B_IMM;
        run_case("PC selected for ALU operand A", ex_in_ctrl,
                 32'h2000, 32'h2004, 32'd7, 32'd100, 32'd12, 5'd10,
                 FWD_NONE, FWD_NONE, 32'd0, 32'd0, 32'h200C, 0, '0,
                 32'd100, 0, 32'h200C);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        ex_in_ctrl.alu_src_a_sel = ALU_SRC_A_ZERO;
        ex_in_ctrl.alu_src_b_sel = ALU_SRC_B_IMM;
        run_case("zero selected for ALU operand A", ex_in_ctrl,
                 32'h2000, 32'h2004, 32'd7, 32'd100, 32'd12, 5'd11,
                 FWD_NONE, FWD_NONE, 32'd0, 32'd0, 32'd12, 0, '0,
                 32'd100, 0, 32'h200C);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_SUB;
        ex_in_ctrl.en_branch = 1'b1;
        ex_in_ctrl.funct3 = BR_BEQ;
        run_case("BEQ taken when operands equal", ex_in_ctrl, 32'h3000,
                 32'h3004, 32'd10, 32'd10, 32'd16, 5'd1, FWD_NONE,
                 FWD_NONE, 32'd0, 32'd0, 32'd0, 0, '0, 32'd10, 1,
                 32'h3010);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_SUB;
        ex_in_ctrl.en_branch = 1'b1;
        ex_in_ctrl.funct3 = BR_BEQ;
        run_case("BEQ not taken when operands differ", ex_in_ctrl,
                 32'h3000, 32'h3004, 32'd10, 32'd9, 32'd16, 5'd1,
                 FWD_NONE, FWD_NONE, 32'd0, 32'd0, 32'd1, 0, '0,
                 32'd9, 0, 32'h3010);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_SUB;
        ex_in_ctrl.en_branch = 1'b1;
        ex_in_ctrl.funct3 = BR_BNE;
        run_case("BNE taken when operands differ", ex_in_ctrl, 32'h3000,
                 32'h3004, 32'd10, 32'd9, 32'd16, 5'd1, FWD_NONE,
                 FWD_NONE, 32'd0, 32'd0, 32'd1, 0, '0, 32'd9, 1,
                 32'h3010);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_SUB;
        ex_in_ctrl.en_branch = 1'b1;
        ex_in_ctrl.funct3 = BR_BLT;
        run_case("BLT signed negative comparison", ex_in_ctrl, 32'h3000,
                 32'h3004, 32'hFFFF_FFFF, 32'd1, 32'd16, 5'd1,
                 FWD_NONE, FWD_NONE, 32'd0, 32'd0, 32'hFFFF_FFFE, 0,
                 '0, 32'd1, 1, 32'h3010);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_SUB;
        ex_in_ctrl.en_branch = 1'b1;
        ex_in_ctrl.funct3 = BR_BGE;
        run_case("BGE signed nonnegative comparison", ex_in_ctrl,
                 32'h3000, 32'h3004, 32'd2, 32'd1, 32'd16, 5'd1,
                 FWD_NONE, FWD_NONE, 32'd0, 32'd0, 32'd1, 0, '0,
                 32'd1, 1, 32'h3010);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_SUB;
        ex_in_ctrl.en_branch = 1'b1;
        ex_in_ctrl.funct3 = BR_BLTU;
        run_case("BLTU unsigned less-than comparison", ex_in_ctrl,
                 32'h3000, 32'h3004, 32'd1, 32'd2, 32'd16, 5'd1,
                 FWD_NONE, FWD_NONE, 32'd0, 32'd0, 32'hFFFF_FFFF, 0,
                 '0, 32'd2, 1, 32'h3010);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_SUB;
        ex_in_ctrl.en_branch = 1'b1;
        ex_in_ctrl.funct3 = BR_BGEU;
        run_case("BGEU unsigned greater-or-equal comparison", ex_in_ctrl,
                 32'h3000, 32'h3004, 32'd2, 32'd1, 32'd16, 5'd1,
                 FWD_NONE, FWD_NONE, 32'd0, 32'd0, 32'd1, 0, '0,
                 32'd1, 1, 32'h3010);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        ex_in_ctrl.en_jump = 1'b1;
        run_case("unconditional jump is taken", ex_in_ctrl, 32'h4000,
                 32'h4004, 32'd1, 32'd2, 32'd24, 5'd1, FWD_NONE,
                 FWD_NONE, 32'd0, 32'd0, 32'd3, 0, '0, 32'd2, 1,
                 32'h4018);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        ex_in_ctrl.en_jump = 1'b1;
        ex_in_ctrl.en_jalr = 1'b1;
        run_case("JALR target uses forwarded base and clears bit zero",
                 ex_in_ctrl, 32'h4000, 32'h4004, 32'h1003, 32'd0,
                 32'd0, 5'd0, FWD_WB, FWD_NONE, 32'd0, 32'h1003,
                 32'h1003, 0, '0, 32'd0, 1, 32'h1002);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        ex_in_ctrl.en_m_ext = 1'b1;
        ex_in_ctrl.m_ext_opcode = M_MUL;
        run_case("MUL result uses selected register operands", ex_in_ctrl,
                 32'h5000, 32'h5004, 32'd63, 32'd7, 32'd0, 5'd4,
                 FWD_NONE, FWD_NONE, 32'd0, 32'd0, 32'd70, 1,
                 32'd441, 32'd7, 0, 32'h5000);

        init_ctrl();
        ex_in_ctrl.alu_opcode = ALU_ADD;
        ex_in_ctrl.en_m_ext = 1'b1;
        ex_in_ctrl.m_ext_opcode = M_DIVU;
        run_case("DIVU result", ex_in_ctrl, 32'h5000, 32'h5004,
                 32'd100, 32'd9, 32'd0, 5'd4, FWD_NONE, FWD_NONE,
                 32'd0, 32'd0, 32'd109, 1, 32'd11, 32'd9, 0,
                 32'h5000);

        $display("===== stage_ex SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 tests, passed, failed);
        if (failed == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: TESTS FAILED");
        $display("============================");
        if (failed != 0) $fatal(1, "stage_ex: %0d test(s) failed", failed);
        $finish;
    end
endmodule
