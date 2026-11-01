//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Copilot
//
// Create Date: 2026-10-15
// Design Name:
// Module Name: tb_simple_divider
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Simulation testbench for simple_divider.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import rv32im_pkg::*;

module tb_simple_divider;
    logic [XLEN-1:0] operand_a;
    logic [XLEN-1:0] operand_b;
    m_ext_opcode_e  m_opcode;
    logic [XLEN-1:0] div_result;
    integer tests_run;
    integer passed;
    integer failed;
    logic quiet_passes = 1'b0;

    localparam m_ext_opcode_e DIV_OPS [0:3] = '{M_DIV, M_DIVU, M_REM, M_REMU};

    simple_divider dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .m_opcode(m_opcode),
        .div_result(div_result)
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
            if (div_result !== expected) begin
                failed = failed + 1;
                $display("[FAIL] %s op=%b a=%h b=%h got=%h expected=%h",
                       label, op, a, b, div_result, expected);
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
        begin
            if (b == '0) begin
                case (op)
                    M_REM, M_REMU: reference_result = a;
                    default:       reference_result = '1;
                endcase
            end else if ((a == 32'h8000_0000) && (b == 32'hFFFF_FFFF) &&
                         ((op == M_DIV) || (op == M_REM))) begin
                reference_result = (op == M_DIV) ? 32'h8000_0000 : 32'd0;
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

    initial begin
        tests_run = 0;
        passed = 0;
        failed = 0;
        operand_a = '0;
        operand_b = '0;
        m_opcode = M_DIV;

        $display("Starting simple divider tests");

        check_case(32'd20, 32'd3, M_DIV, 32'd6, "signed division");
        check_case(32'hFFFF_FFEC, 32'd3, M_DIV, 32'hFFFF_FFFA,
                   "negative dividend division");
        check_case(32'd20, 32'hFFFF_FFFD, M_DIV, 32'hFFFF_FFFA,
                   "negative divisor division");
        check_case(32'hFFFF_FFFF, 32'd2, M_DIVU, 32'h7FFF_FFFF,
                   "unsigned division");
        check_case(32'h8000_0000, 32'hFFFF_FFFF, M_DIV, 32'h8000_0000,
                   "signed division overflow");
        check_case(32'h8000_0000, 32'hFFFF_FFFF, M_REM, 32'h0000_0000,
                   "signed remainder overflow");
        check_case(32'hFFFF_FFEC, 32'd3, M_REM, 32'hFFFF_FFFE,
                   "negative dividend remainder");
        check_case(32'd20, 32'hFFFF_FFFD, M_REM, 32'd2,
                   "negative divisor remainder");
        check_case(32'hFFFF_FFFF, 32'd2, M_REMU, 32'd1,
                   "unsigned remainder");
        check_case(32'h8765_4321, 32'd0, M_DIV, 32'hFFFF_FFFF,
                   "signed divide by zero");
        check_case(32'h8765_4321, 32'd0, M_DIVU, 32'hFFFF_FFFF,
                   "unsigned divide by zero");
        check_case(32'h8765_4321, 32'd0, M_REM, 32'h8765_4321,
                   "signed remainder by zero");
        check_case(32'h8765_4321, 32'd0, M_REMU, 32'h8765_4321,
                   "unsigned remainder by zero");
        check_case(32'd0, 32'd7, M_DIV, 32'd0, "zero dividend");

        quiet_passes = 1'b1;
        $display("--- Begin Random tests ---");
        $display("Testing random division values for 2000 times");
        repeat (2000) begin
            logic [XLEN-1:0] random_a;
            logic [XLEN-1:0] random_b;
            m_ext_opcode_e random_op;
            random_a = $urandom;
            random_b = $urandom;
            random_op = DIV_OPS[$urandom_range(0, 3)];
            check_case(random_a, random_b, random_op,
                       reference_result(random_a, random_b, random_op),
                       "random division");
        end
        foreach (DIV_OPS[i]) begin
            $display("Testing random values of %s for 50 times", op_name(DIV_OPS[i]));
            repeat (50) begin
                logic [XLEN-1:0] random_a;
                logic [XLEN-1:0] random_b;
                random_a = $urandom;
                random_b = $urandom_range(0, 40);
                check_case(random_a, random_b, DIV_OPS[i],
                           reference_result(random_a, random_b, DIV_OPS[i]),
                           "random division operand");
            end
        end
        $display("--- End Random tests ---");
        quiet_passes = 1'b0;

        $display("===== simple_divider SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 tests_run, passed, failed);
        if (failed == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: TESTS FAILED");
        $display("==================================");
        if (failed != 0) $fatal(1, "simple_divider: %0d test(s) failed", failed);
        $finish;
    end
endmodule
