`timescale 1ns/1ps

import rv32im_pkg::*;

module tb_radix4_srt_divider;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start = 1'b0;
    logic [XLEN-1:0] operand_a = '0;
    logic [XLEN-1:0] operand_b = '0;
    m_ext_opcode_e m_opcode = M_DIV;
    logic [XLEN-1:0] div_result;
    logic is_busy;
    logic done;

    localparam integer MAX_CYCLES = 80;
    integer tests_run = 0;
    integer passed = 0;
    integer failed = 0;
    integer total_latency = 0;
    integer min_latency = MAX_CYCLES;
    integer max_latency = 0;
    localparam m_ext_opcode_e DIV_OPS [0:3] =
        '{M_DIV, M_DIVU, M_REM, M_REMU};

    radix4_srt_divider dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .m_opcode(m_opcode),
        .div_result(div_result),
        .is_busy(is_busy),
        .done(done)
    );

    always #5 clk = ~clk;

    function automatic logic [XLEN-1:0] reference_result(
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b,
        input m_ext_opcode_e op
    );
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
    endfunction

    task automatic check_case(
        input string name,
        input m_ext_opcode_e op,
        input logic [XLEN-1:0] a,
        input logic [XLEN-1:0] b
    );
        logic [XLEN-1:0] expected;
        logic expect_busy;
        logic busy_seen;
        logic completed;
        logic case_failed;
        string opcode_name;
        integer cycles;
        begin
            case (op)
                M_DIV:  opcode_name = "DIV";
                M_DIVU: opcode_name = "DIVU";
                M_REM:  opcode_name = "REM";
                M_REMU: opcode_name = "REMU";
                default: opcode_name = "UNKNOWN";
            endcase
            expected = reference_result(a, b, op);
            expect_busy = ((op == M_DIV) || (op == M_DIVU) ||
                           (op == M_REM) || (op == M_REMU)) &&
                          (b != '0) &&
                          !(((op == M_DIV) || (op == M_REM)) &&
                            (a == {1'b1, {(XLEN-1){1'b0}}}) &&
                            (b == {XLEN{1'b1}}));
            busy_seen = 1'b0;
            completed = 1'b0;
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
            if (is_busy === 1'b1) busy_seen = 1'b1;
            if (done === 1'b1) completed = 1'b1;

            @(negedge clk);
            start = 1'b0;
            while ((cycles < MAX_CYCLES) && !completed) begin
                @(posedge clk);
                #1;
                cycles++;
                if (is_busy === 1'b1) busy_seen = 1'b1;
                if (done === 1'b1) completed = 1'b1;
            end

            if (!completed || (busy_seen != expect_busy) ||
                (div_result !== expected)) begin
                case_failed = 1'b1;
                $display("[FAIL] %s op=%b a=%h b=%h result=%h expected=%h busy_seen=%b expected_busy=%b completed=%b",
                         name, op, a, b, div_result, expected,
                         busy_seen, expect_busy, completed);
            end

            if (completed) begin
                @(posedge clk);
                #1;
                if ((is_busy !== 1'b0) || (done !== 1'b0)) begin
                    case_failed = 1'b1;
                    $display("[FAIL] %s divider did not return to idle", name);
                end
            end

            tests_run++;
            if (case_failed) begin
                failed++;
                $display("[FAIL] %s | opcode=%s | dividend=%08h | divisor=%08h | actual=%08h | expected=%08h | latency=%0d cycles",
                         name, opcode_name, a, b, div_result, expected, cycles);
            end else begin
                passed++;
                total_latency += cycles;
                if (cycles < min_latency) min_latency = cycles;
                if (cycles > max_latency) max_latency = cycles;
                $display("[PASS] %s | opcode=%s | dividend=%08h | divisor=%08h | actual=%08h | expected=%08h | latency=%0d cycles",
                         name, opcode_name, a, b, div_result, expected, cycles);
            end
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        $display("===== radix4_srt_divider tests =====");
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
        check_case("invalid opcode completes without iterating", M_MUL,
                   32'h8765_4321, 32'd7);

        foreach (DIV_OPS[op_index]) begin
            repeat (50) begin
                logic [XLEN-1:0] random_a;
                logic [XLEN-1:0] random_b;
                random_a = $urandom;
                random_b = $urandom;
                check_case("random", DIV_OPS[op_index], random_a, random_b);
            end
        end

        $display("===== radix4_srt_divider SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 tests_run, passed, failed);
        if (passed != 0) begin
            $display("Latency (start acceptance to done): min=%0d max=%0d average=%0.2f cycles",
                     min_latency, max_latency, 1.0 * total_latency / passed);
        end
        if (failed != 0)
            $fatal(1, "radix4_srt_divider: %0d test(s) failed", failed);
        $display("RESULT: ALL TESTS PASSED");
        $finish;
    end
endmodule
