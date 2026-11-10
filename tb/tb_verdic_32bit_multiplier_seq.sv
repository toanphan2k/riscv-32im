`timescale 1ns/1ps

import rv32im_pkg::*;

module tb_verdic_32bit_multiplier_seq;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start = 1'b0;
    logic [XLEN-1:0] operand_a = '0;
    logic [XLEN-1:0] operand_b = '0;
    m_ext_opcode_e m_opcode = M_MUL;
    logic [XLEN-1:0] mul_result;
    logic is_busy;
    logic done;

    integer tests_run = 0;
    integer passed = 0;
    integer failed = 0;
    localparam m_ext_opcode_e MUL_OPS [0:3] =
        '{M_MUL, M_MULH, M_MULHSU, M_MULHU};

    verdic_32bit_multiplier_seq dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .m_opcode(m_opcode),
        .mul_result(mul_result),
        .is_busy(is_busy),
        .done(done)
    );

    always #5 clk = ~clk;

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

    task automatic check_case(
        input string name,
        input m_ext_opcode_e op,
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b
    );
        logic [XLEN-1:0] expected;
        logic case_failed;
        integer cycles;
        begin
            expected = reference_result(a, b, op);
            case_failed = 1'b0;
            cycles = 0;

            @(negedge clk);
            m_opcode = op;
            operand_a = a;
            operand_b = b;
            start = 1'b1;

            @(posedge clk);
            #1;
            cycles++;
            if ((is_busy !== 1'b1) || (done !== 1'b0)) begin
                case_failed = 1'b1;
                $display("[FAIL] %s: expected busy after accepting start, busy=%b done=%b",
                         name, is_busy, done);
            end

            @(negedge clk);
            start = 1'b0;
            operand_a = ~a;
            operand_b = ~b;
            m_opcode = M_DIV;

            @(posedge clk);
            #1;
            cycles++;
            if ((is_busy !== 1'b0) || (done !== 1'b1) ||
                (mul_result !== expected)) begin
                case_failed = 1'b1;
                $display("[FAIL] %s op=%b a=%h b=%h result=%h expected=%h busy=%b done=%b",
                         name, op, a, b, mul_result, expected, is_busy, done);
            end

            @(posedge clk);
            #1;
            if ((is_busy !== 1'b0) || (done !== 1'b0)) begin
                case_failed = 1'b1;
                $display("[FAIL] %s: unit did not return to idle, busy=%b done=%b",
                         name, is_busy, done);
            end

            tests_run++;
            if (case_failed) begin
                failed++;
                $display("[FAIL] %s | opcode=%b | operand_a=%08h | operand_b=%08h | actual=%08h | expected=%08h | latency=%0d cycles",
                         name, op, a, b, mul_result, expected, cycles);
            end else begin
                passed++;
                $display("[PASS] %s | opcode=%b | operand_a=%08h | operand_b=%08h | result=%08h | latency=%0d cycles",
                         name, op, a, b, expected, cycles);
            end
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        repeat (1) @(negedge clk);

        $display("===== verdic_32bit_multiplier_seq tests =====");
        check_case("MUL low product", M_MUL, 32'hFFFF_FFFF, 32'd2);
        check_case("MULH signed positive", M_MULH,
                   32'h7FFF_FFFF, 32'h7FFF_FFFF);
        check_case("MULH signed negative", M_MULH,
                   32'h8000_0000, 32'hFFFF_FFFF);
        check_case("MULH both negative", M_MULH,
                   32'hFFFF_FFFE, 32'hFFFF_FFFD);
        check_case("MULHSU negative signed operand", M_MULHSU,
                   32'h8000_0000, 32'hFFFF_FFFF);
        check_case("MULHSU positive signed operand", M_MULHSU,
                   32'h7FFF_FFFF, 32'hFFFF_FFFF);
        check_case("MULHU high-bit operands", M_MULHU,
                   32'hFFFF_FFFF, 32'h8000_0000);
        check_case("MULHU maximum operands", M_MULHU,
                   32'hFFFF_FFFF, 32'hFFFF_FFFF);
        check_case("non-multiply opcode", M_DIV,
                   32'h1234_5678, 32'h8765_4321);

        foreach (MUL_OPS[op_index]) begin
            repeat (50) begin
                logic [XLEN-1:0] random_a;
                logic [XLEN-1:0] random_b;
                random_a = $urandom;
                random_b = $urandom;
                check_case("random multiplication", MUL_OPS[op_index],
                           random_a, random_b);
            end
        end

        $display("===== verdic_32bit_multiplier_seq SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 tests_run, passed, failed);
        if (failed != 0)
            $fatal(1, "verdic_32bit_multiplier_seq: %0d test(s) failed", failed);
        $display("RESULT: ALL TESTS PASSED");
        $finish;
    end
endmodule
