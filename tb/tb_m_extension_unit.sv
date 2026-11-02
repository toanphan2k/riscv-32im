//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Copilot
//
// Create Date: 2026-10-18
// Design Name:
// Module Name: tb_m_extension_unit
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Simulation testbench for m_extension_unit.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import rv32im_pkg::*;

module tb_m_extension_unit;
    logic clk;
    logic rst_n;
    logic start;
    m_ext_opcode_e m_opcode;
    logic [XLEN-1:0] operand_a;
    logic [XLEN-1:0] operand_b;
    logic [XLEN-1:0] m_result;
    logic is_busy;
    logic done;

    int tests = 0;
    int passed = 0;
    int failed = 0;

    m_extesion_unit dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .m_opcode  (m_opcode),
        .operand_a (operand_a),
        .operand_b (operand_b),
        .m_result  (m_result),
        .is_busy   (is_busy),
        .done      (done)
    );

    always #5 clk = ~clk;

    task automatic check_mul(
        input string name,
        input m_ext_opcode_e op,
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b,
        input logic start_value,
        input logic [XLEN-1:0] expected_result
    );
        logic case_passed;
        logic [XLEN-1:0] held_result;
        begin
            @(negedge clk);
            held_result = m_result;
            m_opcode  = op;
            operand_a = a;
            operand_b = b;
            start     = start_value;
            #1;

            case_passed = (m_result === held_result) &&
                          (is_busy === start_value) &&
                          (done === 1'b0);

            if (start_value) begin
                @(posedge clk);
                #1;
                case_passed = case_passed && (is_busy === 1'b1) &&
                              (done === 1'b0) && (m_result === held_result);

                @(negedge clk);
                m_opcode = M_DIV;
                operand_a = 32'd100;
                operand_b = 32'd3;
                start = 1'b1;

                @(posedge clk);
                #1;
                case_passed = case_passed && (is_busy === 1'b0) &&
                              (done === 1'b1) &&
                              (m_result === expected_result);

                @(negedge clk);
                start = 1'b0;
            end

            @(posedge clk);
            #1;
            case_passed = case_passed && (is_busy === 1'b0) &&
                          (done === 1'b0) &&
                          (m_result === expected_result);

            if (!start_value) begin
                @(posedge clk);
                #1;
                case_passed = case_passed && (is_busy === 1'b0) &&
                              (done === 1'b0) &&
                              (m_result === held_result);
            end

            tests++;
            if (case_passed) begin
                passed++;
                $display("[PASS] %s", name);
            end else begin
                failed++;
                $display("[FAIL] %s op=%b a=%h b=%h", name, op, a, b);
                $display("       result=%h expected=%h | busy=%b | done=%b",
                         m_result, expected_result, is_busy, done);
            end
        end
    endtask

    task automatic check_div(
        input string name,
        input m_ext_opcode_e op,
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b,
        input logic [XLEN-1:0] expected_result
    );
        integer cycles;
        logic case_passed;
        begin
            @(negedge clk);
            m_opcode  = op;
            operand_a = a;
            operand_b = b;
            start     = 1'b1;
            #1;
            case_passed = (is_busy === 1'b1) && (done === 1'b0);

            @(posedge clk);
            #1;
            if (b != '0 &&
                !(op == M_DIV && a == 32'h8000_0000 && b == 32'hFFFF_FFFF) &&
                !(op == M_REM && a == 32'h8000_0000 && b == 32'hFFFF_FFFF))
                case_passed = case_passed && (is_busy === 1'b1) &&
                              (done === 1'b0);
            @(negedge clk);
            start = 1'b0;

            cycles = 0;
            while ((done !== 1'b1) && (cycles < XLEN + 2)) begin
                @(posedge clk);
                #1;
                cycles++;
            end

            case_passed = case_passed && (done === 1'b1) &&
                          (is_busy === 1'b0) &&
                          (m_result === expected_result);
            if ((b != '0) &&
                !(op == M_DIV && a == 32'h8000_0000 && b == 32'hFFFF_FFFF) &&
                !(op == M_REM && a == 32'h8000_0000 && b == 32'hFFFF_FFFF))
                case_passed = case_passed && (cycles == XLEN);

            tests++;
            if (case_passed) begin
                passed++;
                $display("[PASS] %s (%0d divider cycles)", name, cycles);
            end else begin
                failed++;
                $display("[FAIL] %s op=%b a=%h b=%h", name, op, a, b);
                $display("       result=%h expected=%h | busy=%b | done=%b | cycles=%0d",
                         m_result, expected_result, is_busy, done, cycles);
            end

            @(posedge clk);
            #1;
            if ((done !== 1'b0) || (is_busy !== 1'b0)) begin
                failed++;
                tests++;
                $display("[FAIL] %s completion did not return to idle", name);
            end
        end
    endtask

    task automatic check_reset_during_operation(input m_ext_opcode_e op);
        begin
            @(negedge clk);
            m_opcode = op;
            operand_a = 32'd100;
            operand_b = 32'd3;
            start = 1'b1;
            @(posedge clk);
            #1;
            start = 1'b0;
            if (is_busy !== 1'b1) begin
                failed++;
                $display("[FAIL] M unit did not start before reset, op=%b", op);
            end

            @(negedge clk);
            rst_n = 1'b0;
            #1;
            tests++;
            if ((is_busy === 1'b0) && (done === 1'b0)) begin
                passed++;
                $display("[PASS] reset aborts an in-flight operation, op=%b", op);
            end else begin
                failed++;
                $display("[FAIL] reset did not clear M unit state, op=%b", op);
            end
            @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        m_opcode = M_MUL;
        operand_a = '0;
        operand_b = '0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        $display("===== m_extension_unit testbench start =====");

        check_mul("MUL low product", M_MUL, 32'hFFFF_FFFF, 32'd2,
                  1'b1, 32'hFFFF_FFFE);
        check_mul("MULH signed high product", M_MULH,
                  32'h8000_0000, 32'h8000_0000, 1'b1, 32'h4000_0000);
        check_mul("MULHSU signed-by-unsigned high product", M_MULHSU,
                  32'h8000_0000, 32'hFFFF_FFFF, 1'b1, 32'h8000_0000);
        check_mul("MULHU unsigned high product", M_MULHU,
                  32'h8000_0000, 32'hFFFF_FFFF, 1'b1, 32'h7FFF_FFFF);
        check_mul("MUL holds previous result when start is low", M_MUL,
              32'd7, 32'd9, 1'b0, 32'h7FFF_FFFF);
        check_mul("MULH negative one squared", M_MULH,
              32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1, 32'd0);
        check_mul("MULHSU negative one times unsigned maximum", M_MULHSU,
              32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1, 32'hFFFF_FFFF);
        check_mul("MULHU unsigned maximum squared", M_MULHU,
              32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1, 32'hFFFF_FFFE);

        check_div("DIV signed negative dividend", M_DIV,
                  32'hFFFF_FFEC, 32'd3, 32'hFFFF_FFFA);
        check_div("DIVU unsigned quotient", M_DIVU,
                  32'hFFFF_FFFF, 32'd2, 32'h7FFF_FFFF);
        check_div("REM signed negative dividend", M_REM,
                  32'hFFFF_FFEC, 32'd3, 32'hFFFF_FFFE);
        check_div("REMU unsigned remainder", M_REMU,
                  32'hFFFF_FFFF, 32'd2, 32'd1);
        check_div("DIV by zero result", M_DIV,
                  32'h1234_5678, 32'd0, 32'hFFFF_FFFF);
        check_div("REM by zero result", M_REM,
                  32'h1234_5678, 32'd0, 32'h1234_5678);
        check_div("DIV signed overflow", M_DIV,
                  32'h8000_0000, 32'hFFFF_FFFF, 32'h8000_0000);
        check_div("REM signed overflow", M_REM,
                  32'h8000_0000, 32'hFFFF_FFFF, 32'd0);
        check_reset_during_operation(M_MUL);
        check_reset_during_operation(M_DIV);

        $display("===== m_extension_unit SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 tests, passed, failed);
        if (failed == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: TESTS FAILED");
        $display("====================================");
        if (failed != 0) $fatal(1, "m_extension_unit: %0d test(s) failed", failed);
        $finish;
    end
endmodule
