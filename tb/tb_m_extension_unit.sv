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
    localparam integer MAX_DIV_CYCLES = XLEN + 3;
    localparam m_ext_opcode_e MUL_OPS [0:3] =
        '{M_MUL, M_MULH, M_MULHSU, M_MULHU};
    localparam m_ext_opcode_e DIV_OPS [0:3] =
        '{M_DIV, M_DIVU, M_REM, M_REMU};

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

    function automatic string opcode_name(input m_ext_opcode_e op);
        case (op)
            M_MUL:    opcode_name = "MUL";
            M_MULH:   opcode_name = "MULH";
            M_MULHSU: opcode_name = "MULHSU";
            M_MULHU:  opcode_name = "MULHU";
            M_DIV:    opcode_name = "DIV";
            M_DIVU:   opcode_name = "DIVU";
            M_REM:    opcode_name = "REM";
            M_REMU:   opcode_name = "REMU";
            default:  opcode_name = "UNKNOWN";
        endcase
    endfunction

    function automatic logic [XLEN-1:0] reference_mul(
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b,
        input m_ext_opcode_e op
    );
        logic signed [63:0] signed_product;
        logic signed [63:0] mixed_product;
        logic [63:0] unsigned_product;
        begin
            signed_product = $signed({{32{a[31]}}, a}) *
                             $signed({{32{b[31]}}, b});
            mixed_product = $signed({{32{a[31]}}, a}) *
                            $signed({32'd0, b});
            unsigned_product = {32'd0, a} * {32'd0, b};
            case (op)
                M_MUL:    reference_mul = signed_product[31:0];
                M_MULH:   reference_mul = signed_product[63:32];
                M_MULHSU: reference_mul = mixed_product[63:32];
                M_MULHU:  reference_mul = unsigned_product[63:32];
                default:  reference_mul = '0;
            endcase
        end
    endfunction

    // Sample after the active edge so timing-annotated outputs can settle.
    task automatic check_mul(
        input string name,
        input m_ext_opcode_e op,
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b,
        input logic start_value,
        input logic [XLEN-1:0] expected_result
    );
        logic case_passed;
        logic result_matched;
        integer settle_cycles;
        begin
            @(posedge clk);
            #1;
            m_opcode  = op;
            operand_a = a;
            operand_b = b;
            start     = start_value;

            case_passed = 1'b0;
            result_matched = 1'b0;
            for (settle_cycles = 0;
                 (settle_cycles < 18) && !result_matched;
                 settle_cycles++) begin
                @(negedge clk);
                #1;
                if ((m_result === expected_result) &&
                    (is_busy === 1'b0) && (done === 1'b1)) begin
                    result_matched = 1'b1;
                    @(negedge clk);
                    #1;
                    case_passed = (m_result === expected_result) &&
                                  (is_busy === 1'b0) &&
                                  (done === 1'b1);
                end
            end

            tests++;
            if (case_passed) begin
                passed++;
            end else begin
                failed++;
            end
            $display("[%s] %s | opcode=%s | OP_A=%08h | OP_B=%08h | actual=%08h | expected=%08h | latency=0 cycles (combinational)",
                     case_passed ? "PASS" : "FAIL", name, opcode_name(op),
                     a, b, m_result, expected_result);
            if (!case_passed)
                $display("       status: done=%b busy=%b", done, is_busy);
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
        logic expect_iterative;
        logic saw_busy;
        logic done_at_completion;
        logic busy_at_completion;
        logic start_state_passed;
        logic completion_passed;
        logic latency_passed;
        logic idle_passed;
        integer expected_cycles;
        begin
            expect_iterative = (b != '0) &&
                               !(((op == M_DIV) || (op == M_REM)) &&
                                 (a == 32'h8000_0000) &&
                                 (b == 32'hFFFF_FFFF));
            expected_cycles = expect_iterative ? XLEN + 1 : 1;
            @(posedge clk);
            #1;
            m_opcode  = op;
            operand_a = a;
            operand_b = b;
            start     = 1'b1;

            @(negedge clk);
            start_state_passed = (is_busy === 1'b0);
            case_passed = start_state_passed;
            saw_busy = 1'b0;

            @(posedge clk);
            cycles = 1;
            @(negedge clk);
            saw_busy = saw_busy || (is_busy === 1'b1);
            start = 1'b0;

            while ((done !== 1'b1) && (cycles < MAX_DIV_CYCLES)) begin
                @(posedge clk);
                cycles++;
                @(negedge clk);
                saw_busy = saw_busy || (is_busy === 1'b1);
            end

            completion_passed = (done === 1'b1) &&
                                (is_busy === 1'b0) &&
                                (m_result === expected_result);
            latency_passed = (cycles >= expected_cycles) &&
                             (cycles <= expected_cycles + 1);
            if (expect_iterative)
                completion_passed = completion_passed && saw_busy;
            case_passed = case_passed && completion_passed &&
                          latency_passed;

            done_at_completion = done;
            busy_at_completion = is_busy;
            @(posedge clk);
            @(negedge clk);
            idle_passed = (done === 1'b0) && (is_busy === 1'b0);
            case_passed = case_passed && idle_passed;

            tests++;
            if (case_passed) begin
                passed++;
            end else begin
                failed++;
            end
            $display("[%s] %s | opcode=%s | OP_A=%08h | OP_B=%08h | actual=%08h | expected=%08h | latency=%0d cycles",
                     case_passed ? "PASS" : "FAIL", name, opcode_name(op),
                     a, b, m_result, expected_result, cycles);
            if (!case_passed)
                $display("       checks: start=%b completion=%b latency=%b idle=%b; completion_status(done=%b busy=%b saw_busy=%b cycles=%0d expected=%0d)",
                         start_state_passed, completion_passed,
                         latency_passed, idle_passed, done_at_completion,
                         busy_at_completion, saw_busy, cycles,
                         expected_cycles);
        end
    endtask

    task automatic check_reset_during_division;
        logic started_before_reset;
        logic reset_cleared;
        begin
            @(posedge clk);
            #1;
            m_opcode = M_DIV;
            operand_a = 32'd100;
            operand_b = 32'd3;
            start = 1'b1;
            @(posedge clk);
            @(negedge clk);
            start = 1'b0;
            started_before_reset = (is_busy === 1'b1);
            if (!started_before_reset) begin
                @(posedge clk);
                @(negedge clk);
                started_before_reset = (is_busy === 1'b1);
            end
            if (!started_before_reset) begin
                $display("[FAIL] divider did not start before reset");
            end

            rst_n = 1'b0;
            @(posedge clk);
            @(negedge clk);
            tests++;
            reset_cleared = (is_busy === 1'b0) && (done === 1'b0);
            if (started_before_reset && reset_cleared) begin
                passed++;
                $display("[PASS] reset aborts an in-flight division");
            end else begin
                failed++;
                if (!reset_cleared)
                    $display("[FAIL] reset did not clear divider state");
            end
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
        check_mul("MUL result is combinational when start is low", M_MUL,
                  32'd7, 32'd9, 1'b0, 32'd63);
        check_mul("MUL zero operand", M_MUL, 32'd0, 32'hFFFF_FFFF,
                  1'b1, 32'd0);
        check_mul("MUL signed minimum times negative one", M_MUL,
                  32'h8000_0000, 32'hFFFF_FFFF, 1'b1, 32'h8000_0000);
        check_mul("MULH signed maximum times maximum", M_MULH,
                  32'h7FFF_FFFF, 32'h7FFF_FFFF, 1'b1,
                  reference_mul(32'h7FFF_FFFF, 32'h7FFF_FFFF, M_MULH));
        check_mul("MULH signed minimum times one", M_MULH,
                  32'h8000_0000, 32'd1, 1'b1, 32'hFFFF_FFFF);
        check_mul("MULHSU negative one times unsigned maximum", M_MULHSU,
                  32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1, 32'hFFFF_FFFF);
        check_mul("MULHSU positive maximum times unsigned maximum", M_MULHSU,
                  32'h7FFF_FFFF, 32'hFFFF_FFFF, 1'b1,
                  reference_mul(32'h7FFF_FFFF, 32'hFFFF_FFFF, M_MULHSU));
        check_mul("MULHU unsigned maximum squared", M_MULHU,
                  32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1, 32'hFFFF_FFFE);
        check_mul("MULHU high bit times high bit", M_MULHU,
                  32'h8000_0000, 32'h8000_0000, 1'b1, 32'h4000_0000);

        foreach (MUL_OPS[op_index]) begin
            repeat (25) begin
                logic [XLEN-1:0] random_a;
                logic [XLEN-1:0] random_b;
                random_a = $urandom;
                random_b = $urandom;
                check_mul("random multiply", MUL_OPS[op_index],
                          random_a, random_b, 1'b1,
                          reference_mul(random_a, random_b,
                                        MUL_OPS[op_index]));
            end
        end

        check_div("DIV signed negative dividend", M_DIV,
                  32'hFFFF_FFEC, 32'd3, 32'hFFFF_FFFA);
        check_div("DIV signed positive operands", M_DIV,
                  32'd100, 32'd9, 32'd11);
        check_div("DIV signed negative divisor", M_DIV,
                  32'd100, 32'hFFFF_FFF7, 32'hFFFF_FFF5);
        check_div("DIV both operands negative", M_DIV,
                  32'hFFFF_FF9C, 32'hFFFF_FFF7, 32'd11);
        check_div("DIV exact quotient", M_DIV,
                  32'd100, 32'd10, 32'd10);
        check_div("DIV zero dividend", M_DIV,
                  32'd0, 32'hFFFF_FFFF, 32'd0);
        check_div("DIV divisor magnitude larger", M_DIV,
                  32'hFFFF_FFFF, 32'd2, 32'd0);
        check_div("DIVU unsigned quotient", M_DIVU,
                  32'hFFFF_FFFF, 32'd2, 32'h7FFF_FFFF);
        check_div("DIVU maximum divided by one", M_DIVU,
                  32'hFFFF_FFFF, 32'd1, 32'hFFFF_FFFF);
        check_div("DIVU zero dividend", M_DIVU,
                  32'd0, 32'hFFFF_FFFF, 32'd0);
        check_div("DIVU divisor greater than dividend", M_DIVU,
                  32'h7FFF_FFFF, 32'h8000_0000, 32'd0);
        check_div("REM signed negative dividend", M_REM,
                  32'hFFFF_FFEC, 32'd3, 32'hFFFF_FFFE);
        check_div("REM exact division", M_REM,
                  32'd100, 32'd10, 32'd0);
        check_div("REM negative divisor", M_REM,
                  32'd100, 32'hFFFF_FFF7, 32'd1);
        check_div("REM zero dividend", M_REM,
                  32'd0, 32'hFFFF_FFFF, 32'd0);
        check_div("REMU unsigned remainder", M_REMU,
                  32'hFFFF_FFFF, 32'd2, 32'd1);
        check_div("REMU divisor greater than dividend", M_REMU,
                  32'd7, 32'd8, 32'd7);
        check_div("REMU maximum divided by one", M_REMU,
                  32'hFFFF_FFFF, 32'd1, 32'd0);
        check_div("DIV by zero result", M_DIV,
                  32'h1234_5678, 32'd0, 32'hFFFF_FFFF);
        check_div("REM by zero result", M_REM,
                  32'h1234_5678, 32'd0, 32'h1234_5678);
        check_div("DIV signed overflow", M_DIV,
                  32'h8000_0000, 32'hFFFF_FFFF, 32'h8000_0000);
        check_div("REM signed overflow", M_REM,
                  32'h8000_0000, 32'hFFFF_FFFF, 32'd0);

        foreach (DIV_OPS[op_index]) begin
            repeat (20) begin
                logic [XLEN-1:0] random_a;
                logic [XLEN-1:0] random_b;
                logic [XLEN-1:0] expected;
                random_a = $urandom;
                random_b = $urandom;
                case (DIV_OPS[op_index])
                    M_DIV: begin
                        if ((random_a == 32'h8000_0000) &&
                            (random_b == 32'hFFFF_FFFF))
                            expected = 32'h8000_0000;
                        else if (random_b == '0)
                            expected = 32'hFFFF_FFFF;
                        else
                            expected = $signed(random_a) / $signed(random_b);
                    end
                    M_DIVU: expected = (random_b == '0) ?
                                       32'hFFFF_FFFF : random_a / random_b;
                    M_REM: begin
                        if ((random_a == 32'h8000_0000) &&
                            (random_b == 32'hFFFF_FFFF))
                            expected = '0;
                        else if (random_b == '0)
                            expected = random_a;
                        else
                            expected = $signed(random_a) % $signed(random_b);
                    end
                    M_REMU: expected = (random_b == '0) ?
                                       random_a : random_a % random_b;
                    default: expected = '0;
                endcase
                check_div("random divide/remainder", DIV_OPS[op_index],
                          random_a, random_b, expected);
            end
        end

        check_reset_during_division();

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
