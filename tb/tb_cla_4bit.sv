//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Copilot
//
// Create Date: 2026-09-28
// Design Name:
// Module Name: tb_cla_4bit
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Simulation testbench for cla_4bit.
//
// Dependencies:
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_cla_4bit;

    // Direct DUT inputs
    logic [3:0] a;
    logic [3:0] b;
    logic       cin;

    // DUT outputs
    logic [3:0] sum;
    logic       cout;
    logic       gen_group;
    logic       prop_group;

    int tests = 0;
    int passed = 0;
    int failed = 0;
    logic quiet_passes = 1'b0;

    // Instantiate Design Under Test (DUT)
    cla_4bit dut (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum),
        .cout(cout),
        .gen_group(gen_group),
        .prop_group(prop_group)
    );

    // Verification task to check DUT outputs against reference math
    task automatic check_result(string test_type);
        logic [4:0] expected;
        logic [4:0] expected_without_cin;
        logic expected_gen_group;
        logic expected_prop_group;
        #1; // Wait 1ns for propagation delay

        expected = {1'b0, a} + {1'b0, b} + cin; // Golden reference calculation
        expected_without_cin = {1'b0, a} + {1'b0, b};
        expected_gen_group = expected_without_cin[4];
        expected_prop_group = &(a ^ b);

        tests++;
        if (({cout, sum} !== expected) ||
            (gen_group !== expected_gen_group) ||
            (prop_group !== expected_prop_group)) begin
            $display("[FAIL] %s | A=%b, B=%b, Cin=%b", test_type, a, b, cin);
            $display("  expected: Cout=%b Sum=%b Gen=%b Prop=%b",
                     expected[4], expected[3:0], expected_gen_group, expected_prop_group);
            $display("  got:      Cout=%b Sum=%b Gen=%b Prop=%b",
                     cout, sum, gen_group, prop_group);
            failed++;
        end else begin
            passed++;
            if (!quiet_passes)
                $display("[PASS] %s | A=%4b (%0d), B=%4b (%0d), Cin=%b | Result: Cout=%b, Sum=%4b (%0d)",
                         test_type, a, a, b, b, cin, cout, sum, sum);
        end
    endtask

    // Main Test Sequence
    initial begin
        $display("==================================================");
        $display("         STARTING CLA 4-BIT TESTBENCH             ");
        $display("==================================================");

        // ----------------------------------------------------
        // SECTION 1: EDGE CASES
        // ----------------------------------------------------
        $display("\n--- Running Directed Edge Cases ---");

        // Case 1: All Zeros
        a = 4'b0000; b = 4'b0000; cin = 1'b0;
        check_result("All Zeros");

        // Case 2: All Zeros with Carry-In
        a = 4'b0000; b = 4'b0000; cin = 1'b1;
        check_result("Zero + Cin");

        // Case 3: Max Values without Carry-In (Overflow test)
        a = 4'b1111; b = 4'b1111; cin = 1'b0;
        check_result("Max Values (15+15)");

        // Case 4: Max Values with Carry-In (Full Overflow test)
        a = 4'b1111; b = 4'b1111; cin = 1'b1;
        check_result("Max Values + Cin (15+15+1)");

        // Case 5: Propagate chain test (1111 + 0000 + 1 => should ripple cin all the way through)
        a = 4'b1111; b = 4'b0000; cin = 1'b1;
        check_result("Full Propagate Chain");

        // Case 6: Alternating bits
        a = 4'b1010; b = 4'b0101; cin = 1'b0;
        check_result("Alternating Bits (10+5)");

        a = 4'b1010; b = 4'b0101; cin = 1'b1;
        check_result("Alternating Bits + Cin");


        // ----------------------------------------------------
        // SECTION 2: RANDOMIZED TESTING
        // ----------------------------------------------------
        $display("\n--- Running 2000 Randomized Tests ---");

        quiet_passes = 1'b1;
        repeat (2000) begin
            a   = $urandom_range(0, 15);
            b   = $urandom_range(0, 15);
            cin = $urandom_range(0, 1);
            check_result("Random Test");
        end
        quiet_passes = 1'b0;

        // ----------------------------------------------------
        // SUMMARY
        // ----------------------------------------------------
        $display("\n============= cla_4bit SUMMARY =============");
        $display("Total: %0d | Passed: %0d | Failed: %0d", tests, passed, failed);
        if (failed == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: TESTS FAILED");
        $display("============================================");
        if (failed != 0) $fatal(1, "cla_4bit: %0d test(s) failed", failed);
        $finish;
    end

endmodule