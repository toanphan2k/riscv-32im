//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Copilot
//
// Create Date: 2026-10-24
// Design Name:
// Module Name: tb_rv32im_core
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Sequential self-checking testbench for rv32im_core.
//
// Dependencies: rv32im_pkg.sv, rv32im_core.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_rv32im_core;

    localparam int IMEM_WORDS = 256;
    localparam int DMEM_WORDS = 256;
    localparam int MAX_PROGRAM_CYCLES = 500;
    localparam int MAX_SEQUENCE_CYCLES = 4 * (MAX_PROGRAM_CYCLES + 4);

    localparam logic [31:0] NOP = 32'h0000_0013;

    logic clk = 1'b0;
    logic rst_n = 1'b0;

    logic [31:0] imem_rdata;
    logic [31:0] imem_addr;
    logic        imem_req;
    logic [31:0] dmem_rdata;
    logic [31:0] dmem_addr;
    logic [3:0]  dmem_wstrobe;
    logic        dmem_req;
    logic        dmem_en_write;
    logic [31:0] dmem_wdata;

    logic [31:0] imem [0:IMEM_WORDS-1];
    logic [31:0] dmem [0:DMEM_WORDS-1];

    int cycle_count = 0;
    int store_count = 0;
    int tests = 0;
    int passed = 0;
    int failed = 0;

    rv32im_core dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .imem_rdata    (imem_rdata),
        .imem_addr     (imem_addr),
        .imem_req      (imem_req),
        .dmem_rdata    (dmem_rdata),
        .dmem_addr     (dmem_addr),
        .dmem_wstrobe  (dmem_wstrobe),
        .dmem_req      (dmem_req),
        .dmem_en_write (dmem_en_write),
        .dmem_wdata    (dmem_wdata)
    );

    always #5 clk = ~clk;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            imem_rdata <= NOP;
        end else if (imem_req) begin
            if ((imem_addr[1:0] != 2'b00) ||
                ((imem_addr >> 2) >= IMEM_WORDS)) begin
                $error("IMEM address invalid/out of range: %08x at cycle %0d",
                       imem_addr, cycle_count);
                failed <= failed + 1;
                imem_rdata <= NOP;
            end else begin
                imem_rdata <= imem[imem_addr[31:2]];
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            dmem_rdata <= '0;
        end else if (dmem_req) begin
            if ((dmem_addr[1:0] != 2'b00) ||
                ((dmem_addr >> 2) >= DMEM_WORDS)) begin
                $error("DMEM address invalid/out of range: %08x at cycle %0d",
                       dmem_addr, cycle_count);
                failed <= failed + 1;
                dmem_rdata <= '0;
            end else begin
                dmem_rdata <= dmem[dmem_addr[31:2]];

                if (dmem_en_write) begin
                    if (dmem_wstrobe[0])
                        dmem[dmem_addr[31:2]][7:0] <= dmem_wdata[7:0];
                    if (dmem_wstrobe[1])
                        dmem[dmem_addr[31:2]][15:8] <= dmem_wdata[15:8];
                    if (dmem_wstrobe[2])
                        dmem[dmem_addr[31:2]][23:16] <= dmem_wdata[23:16];
                    if (dmem_wstrobe[3])
                        dmem[dmem_addr[31:2]][31:24] <= dmem_wdata[31:24];
                    store_count <= store_count + 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;

            if ((^imem_req) === 1'bx) begin
                $error("imem_req is X at cycle %0d", cycle_count);
                failed <= failed + 1;
            end

            if ((^dmem_req) === 1'bx) begin
                $error("dmem_req is X at cycle %0d", cycle_count);
                failed <= failed + 1;
            end

            if (dmem_req && dmem_en_write &&
                ((^dmem_wstrobe) === 1'bx)) begin
                $error("dmem_wstrobe contains X on a store at cycle %0d",
                       cycle_count);
                failed <= failed + 1;
            end

            if (dmem_req && dmem_en_write && (dmem_wstrobe == 4'b0000)) begin
                $error("Store request has zero byte strobe at cycle %0d",
                       cycle_count);
                failed <= failed + 1;
            end
        end
    end

    task automatic check_ram_word(
        input int word_index,
        input logic [31:0] expected,
        input string description
    );
        begin
            tests++;
            if (dmem[word_index] !== expected) begin
                failed++;
                $error("[FAIL] %s: dmem[%0d] expected %08x, got %08x",
                       description, word_index, expected, dmem[word_index]);
            end else begin
                passed++;
                $display("[PASS] %s: dmem[%0d] = %08x",
                         description, word_index, expected);
            end
        end
    endtask

    task automatic run_program(
        input string name,
        input string mem_file,
        input int completion_word,
        input logic [31:0] pass_marker,
        input logic [31:0] fail_marker,
        input logic has_fail_marker
    );
        logic complete;
        int cycles;
        begin
            $display("");
            $display("===== Running %s (%s) =====", name, mem_file);
            rst_n = 1'b0;

            for (int i = 0; i < IMEM_WORDS; i++)
                imem[i] = NOP;
            $readmemh(mem_file, imem);

            for (int i = 0; i < DMEM_WORDS; i++)
                dmem[i] = '0;
            store_count = 0;
            cycle_count = 0;

            repeat (4) @(posedge clk);
            @(negedge clk);
            rst_n = 1'b1;

            complete = 1'b0;
            cycles = 0;
            while (!complete && cycles < MAX_PROGRAM_CYCLES) begin
                @(negedge clk);
                cycles++;
                if (dmem[completion_word] === pass_marker)
                    complete = 1'b1;
                else if (has_fail_marker &&
                         dmem[completion_word] === fail_marker)
                    complete = 1'b1;
            end

            tests++;
            if (!complete) begin
                failed++;
                $error("[FAIL] %s timed out after %0d cycles",
                       name, MAX_PROGRAM_CYCLES);
            end else if (dmem[completion_word] !== pass_marker) begin
                failed++;
                $error("[FAIL] %s wrote failure marker %08x to dmem[%0d]",
                       name, fail_marker, completion_word);
            end else begin
                passed++;
                $display("[PASS] %s completed in %0d cycles with PASS marker %08x",
                         name, cycles, pass_marker);
            end
        end
    endtask

    initial begin : test_sequence
        $display("==================================================");
        $display(" rv32im_core sequential program testbench");
        $display("==================================================");

        run_program("Level 1: basic instructions",
                    "basic_instructions_test.mem",
                    64, 32'h0000_0055, 32'h0000_00EE, 1'b1);
        check_ram_word(64, 32'h0000_0055,
                       "Basic instruction PASS signature");

        run_program("Level 2: pipeline hazards",
                    "pipeline_harzard_test.mem",
                    67, 32'h0000_0014, 32'h0, 1'b0);
        check_ram_word(64, 32'd30, "Pipeline result x3");
        check_ram_word(65, 32'd50, "Load-use result x7");
        check_ram_word(66, 32'd7, "Taken-branch target result x9");
        check_ram_word(67, 32'd20, "Pipeline test completion store");
        check_ram_word(68, 32'd0, "Wrong-path store was flushed");
        tests++;
        if (store_count != 4) begin
            failed++;
            $error("[FAIL] Pipeline test expected 4 stores, observed %0d",
                   store_count);
        end else begin
            passed++;
            $display("[PASS] Pipeline test observed exactly 4 stores");
        end

        run_program("Level 3: load/store subsystem",
                    "load_store_subsystem_test.mem",
                    128, 32'h0000_0055, 32'h0000_00EE, 1'b1);
        check_ram_word(64, 32'h80FF_8001, "Seed word and byte address");
        check_ram_word(65, 32'h4433_2211, "SB byte lanes and strobes");
        check_ram_word(66, 32'h0456_0123, "SH halfword lanes and strobes");
        check_ram_word(68, 32'h89AB_C123, "SW/LW word address");
        check_ram_word(128, 32'h0000_0055,
                       "Load/store subsystem PASS signature");

        run_program("Level 4: control flow and corner cases",
                    "control_flow_corner_cases_test.mem",
                    64, 32'h0000_0055, 32'h0000_00EE, 1'b1);
        check_ram_word(64, 32'h0000_0055,
                       "Control-flow PASS signature");

        $display("");
        $display("===== rv32im_core SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 tests, passed, failed);
        if (failed == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: TESTS FAILED");
        $display("===============================");
        if (failed != 0) $fatal(1, "rv32im_core: %0d test(s) failed", failed);
        $finish;
    end

    initial begin
        repeat (MAX_SEQUENCE_CYCLES) @(posedge clk);
        $fatal(1, "TIMEOUT: test sequence did not finish");
    end

endmodule
