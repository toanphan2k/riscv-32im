//////////////////////////////////////////////////////////////////////////////////
// Shared RV32M tests for the iterative radix divider variants.
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import rv32im_pkg::*;

module tb_radix_divider_test_runner #(
    parameter integer DIVIDER_KIND = 0
);
    logic clk;
    logic rst_n;
    logic start;
    logic [XLEN-1:0] operand_a;
    logic [XLEN-1:0] operand_b;
    m_ext_opcode_e m_opcode;
    logic [XLEN-1:0] div_result;
    logic is_busy;
    logic done;

    integer tests_run;
    integer failed;

    localparam integer MAX_CYCLES = 80;
    localparam m_ext_opcode_e DIV_OPS [0:3] =
        '{M_DIV, M_DIVU, M_REM, M_REMU};

    generate
        if (DIVIDER_KIND == 0) begin : GEN_RADIX2_NONRES
            radix2_nonres_divider dut (
                .clk(clk), .rst_n(rst_n), .start(start),
                .operand_a(operand_a), .operand_b(operand_b),
                .m_opcode(m_opcode), .div_result(div_result),
                .is_busy(is_busy), .done(done)
            );
        end else if (DIVIDER_KIND == 1) begin : GEN_RADIX4_RES
            radix4_res_divider dut (
                .clk(clk), .rst_n(rst_n), .start(start),
                .operand_a(operand_a), .operand_b(operand_b),
                .m_opcode(m_opcode), .div_result(div_result),
                .is_busy(is_busy), .done(done)
            );
        end else if (DIVIDER_KIND == 2) begin : GEN_RADIX4_NONRES
            radix4_nonres_divider dut (
                .clk(clk), .rst_n(rst_n), .start(start),
                .operand_a(operand_a), .operand_b(operand_b),
                .m_opcode(m_opcode), .div_result(div_result),
                .is_busy(is_busy), .done(done)
            );
        end else begin : GEN_RADIX2_RES
            radix2_res_divider dut (
                .clk(clk), .rst_n(rst_n), .start(start),
                .operand_a(operand_a), .operand_b(operand_b),
                .m_opcode(m_opcode), .div_result(div_result),
                .is_busy(is_busy), .done(done)
            );
        end
    endgenerate

    always #5 clk = ~clk;

    function automatic logic [XLEN-1:0] reference_result(
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b,
        input m_ext_opcode_e op
    );
        begin
            if (b == '0) begin
                case (op)
                    M_REM, M_REMU: reference_result = a;
                    default:       reference_result = {XLEN{1'b1}};
                endcase
            end else if ((a == {1'b1, {(XLEN-1){1'b0}}}) &&
                         (b == {XLEN{1'b1}}) &&
                         ((op == M_DIV) || (op == M_REM))) begin
                reference_result = (op == M_DIV) ?
                                   {1'b1, {(XLEN-1){1'b0}}} : '0;
            end else begin
                case (op)
                    M_DIV:  reference_result = $signed(a) / $signed(b);
                    M_DIVU: reference_result = a / b;
                    M_REM:  reference_result = $signed(a) % $signed(b);
                    M_REMU: reference_result = a % b;
                    default: reference_result = '0;
                endcase
            end
        end
    endfunction

    function automatic string op_name(input m_ext_opcode_e op);
        begin
            case (op)
                M_DIV:  op_name = "DIV";
                M_DIVU: op_name = "DIVU";
                M_REM:  op_name = "REM";
                M_REMU: op_name = "REMU";
                default: op_name = "UNKNOWN";
            endcase
        end
    endfunction

    function automatic string divider_name();
        begin
            case (DIVIDER_KIND)
                0: divider_name = "radix2_nonres_divider";
                1: divider_name = "radix4_res_divider";
                2: divider_name = "radix4_nonres_divider";
                default: divider_name = "radix2_res_divider";
            endcase
        end
    endfunction

    task automatic check_case(
        input string name,
        input m_ext_opcode_e op,
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b
    );
        logic [XLEN-1:0] expected;
        integer cycles;
        logic busy_seen;
        logic completed;
        logic case_failed;
        logic expect_busy;
        begin
            expected = reference_result(a, b, op);
            busy_seen = 1'b0;
            completed = 1'b0;
            case_failed = 1'b0;
            cycles = 0;
            expect_busy = (b != '0) &&
                          !(((op == M_DIV) || (op == M_REM)) &&
                            (a == {1'b1, {(XLEN-1){1'b0}}}) &&
                            (b == {XLEN{1'b1}}));

            @(negedge clk);
            m_opcode = op;
            operand_a = a;
            operand_b = b;
            start = 1'b1;

            @(posedge clk);
            #1;
            cycles = cycles + 1;
            if (is_busy === 1'b1) busy_seen = 1'b1;
            if (done === 1'b1) completed = 1'b1;

            @(negedge clk);
            start = 1'b0;

            while ((cycles < MAX_CYCLES) && !completed) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
                if (is_busy === 1'b1) busy_seen = 1'b1;
                if (done === 1'b1) completed = 1'b1;
            end

            if (!completed) begin
                case_failed = 1'b1;
                $display("[FAIL] %s %s timeout op=%s a=%h b=%h",
                         divider_name(), name, op_name(op), a, b);
            end else if (busy_seen != expect_busy) begin
                case_failed = 1'b1;
                $display("[FAIL] %s %s busy=%b expected=%b",
                         divider_name(), name, busy_seen, expect_busy);
            end else if (div_result !== expected) begin
                case_failed = 1'b1;
                $display("[FAIL] %s %s op=%s a=%h b=%h got=%h expected=%h",
                         divider_name(), name, op_name(op), a, b,
                         div_result, expected);
            end

            if (completed) begin
                @(posedge clk);
                #1;
                if ((is_busy !== 1'b0) || (done !== 1'b0)) begin
                    case_failed = 1'b1;
                    $display("[FAIL] %s %s did not return idle",
                             divider_name(), name);
                end
            end

            tests_run = tests_run + 1;
            if (case_failed) failed = failed + 1;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        start = 1'b0;
        operand_a = '0;
        operand_b = '0;
        m_opcode = M_DIV;
        tests_run = 0;
        failed = 0;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        $display("===== %s tests =====", divider_name());

        check_case("DIV positive", M_DIV, 32'd20, 32'd3);
        check_case("DIV negative dividend", M_DIV, 32'hFFFF_FFEC, 32'd3);
        check_case("DIV negative divisor", M_DIV, 32'd20, 32'hFFFF_FFFD);
        check_case("DIV both negative", M_DIV, 32'hFFFF_FFEC, 32'hFFFF_FFFD);
        check_case("DIV signed overflow", M_DIV, 32'h8000_0000, 32'hFFFF_FFFF);
        check_case("DIV by zero", M_DIV, 32'h8765_4321, 32'd0);
        check_case("DIV zero dividend", M_DIV, 32'd0, 32'd7);
        check_case("DIV equal operands", M_DIV, 32'hFFFF_FFFF, 32'hFFFF_FFFF);

        check_case("DIVU high-bit operands", M_DIVU, 32'hFFFF_FFFF, 32'h8000_0000);
        check_case("DIVU divisor larger", M_DIVU, 32'h7FFF_FFFF, 32'h8000_0000);
        check_case("DIVU by one", M_DIVU, 32'hFEDC_BA98, 32'd1);
        check_case("DIVU by zero", M_DIVU, 32'h8765_4321, 32'd0);
        check_case("DIVU zero dividend", M_DIVU, 32'd0, 32'hFFFF_FFFF);

        check_case("REM positive", M_REM, 32'd20, 32'd3);
        check_case("REM negative dividend", M_REM, 32'hFFFF_FFEC, 32'd3);
        check_case("REM negative divisor", M_REM, 32'd20, 32'hFFFF_FFFD);
        check_case("REM both negative", M_REM, 32'hFFFF_FFEC, 32'hFFFF_FFFD);
        check_case("REM signed overflow", M_REM, 32'h8000_0000, 32'hFFFF_FFFF);
        check_case("REM by zero", M_REM, 32'h8765_4321, 32'd0);
        check_case("REM zero dividend", M_REM, 32'd0, 32'hFFFF_FFFF);

        check_case("REMU high-bit operands", M_REMU, 32'hFFFF_FFFF, 32'h8000_0000);
        check_case("REMU divisor larger", M_REMU, 32'h7FFF_FFFF, 32'h8000_0000);
        check_case("REMU by one", M_REMU, 32'hFEDC_BA98, 32'd1);
        check_case("REMU by zero", M_REMU, 32'h8765_4321, 32'd0);
        check_case("REMU zero dividend", M_REMU, 32'd0, 32'hFFFF_FFFF);

        foreach (DIV_OPS[op_index]) begin
            repeat (50) begin
                logic [XLEN-1:0] random_a;
                logic [XLEN-1:0] random_b;
                random_a = $urandom;
                random_b = $urandom;
                check_case("random", DIV_OPS[op_index], random_a, random_b);
            end
        end

        $display("===== %s SUMMARY =====", divider_name());
        $display("Total: %0d | Failed: %0d", tests_run, failed);
        if (failed != 0) $fatal(1, "%s: %0d test(s) failed",
                                divider_name(), failed);
        $display("RESULT: ALL TESTS PASSED");
        $finish;
    end
endmodule
