//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Copilot
//
// Create Date: 2026-09-25
// Design Name:
// Module Name: tb_alu_32rv
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Simulation testbench for alu_32rv.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import rv32im_pkg::*;

module tb_alu_32rv;

    logic [31:0] operand_a;
    logic [31:0] operand_b;
    alu_opcode_e opcode;
    logic [31:0] result;
    logic zero_flag;
    logic less_than_flag;
    logic less_than_unsigned_flag;
    int tests = 0;
    int passed = 0;
    int failed = 0;
    logic quiet_passes = 1'b0;

    localparam alu_opcode_e ALU_OPS [0:9] = '{
        ALU_ADD, ALU_SUB, ALU_SLL, ALU_SLT, ALU_SLTU,
        ALU_XOR, ALU_SRL, ALU_SRA, ALU_OR, ALU_AND
    };

    alu_rv32 dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .opcode(opcode),
        .result(result),
        .zero_flag(zero_flag),
        .less_than_flag(less_than_flag),
        .less_than_unsigned_flag(less_than_unsigned_flag)
    );

    task automatic check_case(
        input logic [31:0] a,
        input logic [31:0] b,
        input alu_opcode_e op,
        input logic [31:0] expected_result,
        input logic expected_zero,
        input logic expected_lt,
        input logic expected_ltu,
        input string label
    );
        begin
            operand_a = a;
            operand_b = b;
            opcode    = op;

            #1;

            tests++;
            if ((result !== expected_result) ||
                (zero_flag !== expected_zero) ||
                (less_than_flag !== expected_lt) ||
                (less_than_unsigned_flag !== expected_ltu)) begin
                failed++;
                $display("[FAIL] %s", label);
                $display("  a=%0d b=%0d op=%0d", a, b, op);
                $display("  got: result=%0d zero=%0b lt=%0b ltu=%0b", result, zero_flag, less_than_flag, less_than_unsigned_flag);
                $display("  exp: result=%0d zero=%0b lt=%0b ltu=%0b", expected_result, expected_zero, expected_lt, expected_ltu);
            end else begin
                passed++;
                if (!quiet_passes) $display("[PASS] %s", label);
            end
        end
    endtask

    function automatic logic [31:0] reference_result(
        input logic [31:0] a,
        input logic [31:0] b,
        input alu_opcode_e op
    );
        begin
            case (op)
                ALU_ADD:  reference_result = a + b;
                ALU_SUB:  reference_result = a - b;
                ALU_SLL:  reference_result = a << b[4:0];
                ALU_SLT:  reference_result = {31'd0, ($signed(a) < $signed(b))};
                ALU_SLTU: reference_result = {31'd0, (a < b)};
                ALU_XOR:  reference_result = a ^ b;
                ALU_SRL:  reference_result = a >> b[4:0];
                ALU_SRA:  reference_result = $signed(a) >>> b[4:0];
                ALU_OR:   reference_result = a | b;
                ALU_AND:  reference_result = a & b;
                default:  reference_result = '0;
            endcase
        end
    endfunction

    function automatic string op_name(input alu_opcode_e op);
        begin
            case (op)
                ALU_ADD:  op_name = "ADD";
                ALU_SUB:  op_name = "SUB";
                ALU_SLL:  op_name = "SLL";
                ALU_SLT:  op_name = "SLT";
                ALU_SLTU: op_name = "SLTU";
                ALU_XOR:  op_name = "XOR";
                ALU_SRL:  op_name = "SRL";
                ALU_SRA:  op_name = "SRA";
                ALU_OR:   op_name = "OR";
                ALU_AND:  op_name = "AND";
                default:  op_name = "UNKNOWN";
            endcase
        end
    endfunction

    task automatic check_random(
        input logic [31:0] a,
        input logic [31:0] b,
        input alu_opcode_e op,
        input string label
    );
        logic [31:0] expected_result;
        logic expected_lt;
        logic expected_ltu;
        begin
            expected_result = reference_result(a, b, op);
            expected_lt = ((op == ALU_SLT) || (op == ALU_SUB)) &&
                          ($signed(a) < $signed(b));
            expected_ltu = ((op == ALU_SLTU) || (op == ALU_SUB)) &&
                           (a < b);
            check_case(
                a, b, op, expected_result, (expected_result == 32'd0),
                expected_lt, expected_ltu, label
            );
        end
    endtask

    initial begin
        $display("Starting ALU testbench");

        // ADD
        check_case(32'd10, 32'd5, ALU_ADD, 32'd15, 1'b0, 1'b0, 1'b0, "ADD");

        // SUB
        check_case(32'd10, 32'd5, ALU_SUB, 32'd5, 1'b0, 1'b0, 1'b0, "SUB");

        // SUB equality drives the zero flag used by BEQ/BNE
        check_case(32'd5, 32'd5, ALU_SUB, 32'd0, 1'b1, 1'b0, 1'b0, "SUB equal");

        // AND with zero result
        check_case(32'hAA55_AA55, 32'h55AA_55AA, ALU_AND, 32'd0, 1'b1, 1'b0, 1'b0, "AND");

        // OR
        check_case(32'h0F0F_0000, 32'h0000_F0F0, ALU_OR, 32'h0F0F_F0F0, 1'b0, 1'b0, 1'b0, "OR");

        // XOR
        check_case(32'hA5A5_A5A5, 32'h5A5A_5A5A, ALU_XOR, 32'hFFFF_FFFF, 1'b0, 1'b0, 1'b0, "XOR");

        // SLL
        check_case(32'd3, 32'd2, ALU_SLL, 32'd12, 1'b0, 1'b0, 1'b0, "SLL");

        // SRL
        check_case(32'h8000_0001, 32'd1, ALU_SRL, 32'h4000_0000, 1'b0, 1'b0, 1'b0, "SRL");

        // SRA
        check_case(32'h8000_0001, 32'd1, ALU_SRA, 32'hC000_0000, 1'b0, 1'b0, 1'b0, "SRA");

        // SLT signed compare
        check_case(32'hFFFF_FFFF, 32'd1, ALU_SLT, 32'd1, 1'b0, 1'b1, 1'b0, "SLT");

        // SLT must account for signed subtraction overflow
        check_case(32'h8000_0000, 32'd1, ALU_SLT, 32'd1, 1'b0, 1'b1, 1'b0, "SLT overflow");

        // SLTU unsigned compare
        check_case(32'd1, 32'd2, ALU_SLTU, 32'd1, 1'b0, 1'b0, 1'b1, "SLTU");

        // SLTU must use carry/borrow rather than the subtraction sign bit
        check_case(32'hFFFF_FFFF, 32'd1, ALU_SLTU, 32'd0, 1'b1, 1'b0, 1'b0, "SLTU high unsigned");

        quiet_passes = 1'b1;
        $display("--- Begin Random tests ---");
        $display("Testing Random Value for 2000 times");
        repeat (2000) begin
            check_random(
                $urandom, $urandom,
                ALU_OPS[$urandom_range(0, 9)], "random ALU operation"
            );
        end
        foreach (ALU_OPS[i]) begin
            $display("Testing random value of %s for 50 times", op_name(ALU_OPS[i]));
            repeat (50) begin
                check_random(
                    $urandom, $urandom_range(0, 40),
                    ALU_OPS[i], "random operand for ALU operation"
                );
            end
        end
        $display("--- End Random tests ---");
        quiet_passes = 1'b0;

        $display("===== alu_rv32 SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d", tests, passed, failed);
        if (failed == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: TESTS FAILED");
        $display("============================");
        if (failed != 0) $fatal(1, "alu_rv32: %0d test(s) failed", failed);
        $finish;
    end

endmodule
