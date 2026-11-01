//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Copilot
//
// Create Date: 2026-10-15
// Design Name:
// Module Name: tb_simple_multiplier
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Simulation testbench for simple_multiplier.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import rv32im_pkg::*;

module tb_simple_multiplier;
    logic [XLEN-1:0] operand_a;
    logic [XLEN-1:0] operand_b;
    m_ext_opcode_e  m_opcode;
    logic [XLEN-1:0] mul_result;
    integer tests_run;
    integer passed;
    integer failed;
    logic quiet_passes = 1'b0;

    localparam m_ext_opcode_e MUL_OPS [0:3] = '{M_MUL, M_MULH, M_MULHSU, M_MULHU};

    simple_multiplier dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .m_opcode(m_opcode),
        .mul_result(mul_result)
    );

    task automatic check_case(
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b,
        input m_ext_opcode_e op,
        input logic [XLEN-1:0] expected,
        input string label
    );
        begin
            operand_a = a;
            operand_b = b;
            m_opcode = op;
            #1;

            tests_run = tests_run + 1;
            if (mul_result !== expected) begin
                failed = failed + 1;
                $display("[FAIL] %s op=%b a=%h b=%h got=%h expected=%h",
                       label, op, a, b, mul_result, expected);
            end else begin
                passed = passed + 1;
                if (!quiet_passes) $display("[PASS] %s", label);
            end
        end
    endtask

    function automatic logic [XLEN-1:0] reference_result(
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
                M_MUL:    reference_result = signed_product[31:0];
                M_MULH:   reference_result = signed_product[63:32];
                M_MULHSU: reference_result = mixed_product[63:32];
                M_MULHU:  reference_result = unsigned_product[63:32];
                default:  reference_result = '0;
            endcase
        end
    endfunction

    function automatic string op_name(input m_ext_opcode_e op);
        begin
            case (op)
                M_MUL:    op_name = "MUL";
                M_MULH:   op_name = "MULH";
                M_MULHSU: op_name = "MULHSU";
                M_MULHU:  op_name = "MULHU";
                default:  op_name = "UNKNOWN";
            endcase
        end
    endfunction

    initial begin
        tests_run = 0;
        passed = 0;
        failed = 0;
        operand_a = '0;
        operand_b = '0;
        m_opcode = M_MUL;

        $display("Starting simple multiplier tests");

        check_case(32'hFFFF_FFFF, 32'd2, M_MUL, 32'hFFFF_FFFE,
                   "low product");
        check_case(32'h8000_0000, 32'h8000_0000, M_MULH,
                   32'h4000_0000, "signed high product");
        check_case(32'h8000_0000, 32'hFFFF_FFFF, M_MULHSU,
                   32'h8000_0000, "signed by unsigned high product");
        check_case(32'h8000_0000, 32'hFFFF_FFFF, M_MULHU,
                   32'h7FFF_FFFF, "unsigned high product");
        check_case(32'hFFFF_FFFF, 32'hFFFF_FFFF, M_MULHU,
                   32'hFFFF_FFFE, "maximum unsigned product high");
        check_case(32'h7FFF_FFFF, 32'h0000_0002, M_MULH,
                   32'h0000_0000, "positive signed high product");
        check_case(32'h1234_5678, 32'h8765_4321, M_DIV, 32'd0,
                   "non-multiply opcode");

        quiet_passes = 1'b1;
        $display("--- Begin Random tests ---");
        $display("Testing random multiplication values for 2000 times");
        repeat (2000) begin
            logic [XLEN-1:0] random_a;
            logic [XLEN-1:0] random_b;
            m_ext_opcode_e random_op;
            random_a = $urandom;
            random_b = $urandom;
            random_op = MUL_OPS[$urandom_range(0, 3)];
            check_case(random_a, random_b, random_op,
                       reference_result(random_a, random_b, random_op),
                       "random multiplication");
        end
        foreach (MUL_OPS[i]) begin
            $display("Testing random values of %s for 50 times", op_name(MUL_OPS[i]));
            repeat (50) begin
                logic [XLEN-1:0] random_a;
                logic [XLEN-1:0] random_b;
                random_a = $urandom;
                random_b = $urandom;
                check_case(random_a, random_b, MUL_OPS[i],
                           reference_result(random_a, random_b, MUL_OPS[i]),
                           "random multiplication operands");
            end
        end
        $display("--- End Random tests ---");
        quiet_passes = 1'b0;

        $display("===== simple_multiplier SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 tests_run, passed, failed);
        if (failed == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: TESTS FAILED");
        $display("=====================================");
        if (failed != 0) $fatal(1, "simple_multiplier: %0d test(s) failed", failed);
        $finish;
    end
endmodule
