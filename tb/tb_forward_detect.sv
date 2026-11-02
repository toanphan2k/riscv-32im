//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Copilot
//
// Create Date: 2026-10-16
// Design Name:
// Module Name: tb_forward_unit
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: Simulation testbench for forward_unit.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
import rv32im_pkg::*;

module tb_forward_unit;

    logic        i_mem_rd_wren, i_wb_rd_wren;
    logic [4:0]  i_rs1_addr, i_rs2_addr, i_mem_rd_addr, i_wb_rd_addr;
    logic        o_fw_a_mem, o_fw_a_wb;
    logic        o_fw_b_mem, o_fw_b_wb;
    fwd_sel_e    o_fw_a, o_fw_b;

    always_comb begin
        case ({o_fw_a_mem, o_fw_a_wb})
            2'b10:   o_fw_a = FWD_MEM;
            2'b01:   o_fw_a = FWD_WB;
            default: o_fw_a = FWD_NONE;
        endcase
        case ({o_fw_b_mem, o_fw_b_wb})
            2'b10:   o_fw_b = FWD_MEM;
            2'b01:   o_fw_b = FWD_WB;
            default: o_fw_b = FWD_NONE;
        endcase
    end

    int tests = 0;
    int errors = 0;

    forward_unit dut (
        .mem_rd_wren (i_mem_rd_wren),
        .wb_rd_wren  (i_wb_rd_wren),
        .ex_rs1_addr (i_rs1_addr),
        .ex_rs2_addr (i_rs2_addr),
        .mem_rd_addr (i_mem_rd_addr),
        .wb_rd_addr  (i_wb_rd_addr),
        .fwd_a_mem   (o_fw_a_mem),
        .fwd_a_wb    (o_fw_a_wb),
        .fwd_b_mem   (o_fw_b_mem),
        .fwd_b_wb    (o_fw_b_wb)
    );

    task automatic check_case(
        input string name,
        input logic mem_we,
        input logic wb_we,
        input logic [4:0] rs1,
        input logic [4:0] rs2,
        input logic [4:0] mem_rd,
        input logic [4:0] wb_rd,
        input fwd_sel_e exp_a,
        input fwd_sel_e exp_b
    );
        begin
            i_mem_rd_wren = mem_we;
            i_wb_rd_wren  = wb_we;
            i_rs1_addr    = rs1;
            i_rs2_addr    = rs2;
            i_mem_rd_addr = mem_rd;
            i_wb_rd_addr  = wb_rd;
            #10;
            tests++;
            if ((o_fw_a !== exp_a) || (o_fw_b !== exp_b) ||
                (o_fw_a_mem && o_fw_a_wb) || (o_fw_b_mem && o_fw_b_wb)) begin
                errors++;
                $display("[FAIL] [%0t] %-38s A expected=%0d got=%0d; B expected=%0d got=%0d",
                         $time, name, exp_a, o_fw_a, exp_b, o_fw_b);
            end else begin
                $display("[PASS] [%0t] %s", $time, name);
            end
        end
    endtask

    initial begin
        $display("===== forward_unit testbench start =====");

        // No forwarding enables active.
        check_case("T01: both write enables off",
                   0, 0, 5'd1, 5'd2, 5'd1, 5'd2,
                   FWD_NONE, FWD_NONE);

        // MEM-stage producer matches rs1 or rs2 independently.
        check_case("T02: MEM match rs1",
                   1, 0, 5'd5, 5'd7, 5'd5, 5'd9,
                   FWD_MEM, FWD_NONE);

        check_case("T03: MEM match rs2",
                   1, 0, 5'd5, 5'd7, 5'd7, 5'd9,
                   FWD_NONE, FWD_MEM);

        // WB-stage producer matches rs1 or rs2 independently.
        check_case("T04: WB match rs1",
                   0, 1, 5'd4, 5'd8, 5'd3, 5'd4,
                   FWD_WB, FWD_NONE);

        check_case("T05: WB match rs2",
                   0, 1, 5'd4, 5'd8, 5'd3, 5'd8,
                   FWD_NONE, FWD_WB);

        // Both source operands match MEM.
        check_case("T06: both operands match MEM",
                   1, 0, 5'd6, 5'd6, 5'd6, 5'd9,
                   FWD_MEM, FWD_MEM);

        // Both source operands match WB.
        check_case("T07: both operands match WB",
                   0, 1, 5'd10, 5'd10, 5'd3, 5'd10,
                   FWD_WB, FWD_WB);

        // Priority: when MEM and WB both match the same source, MEM wins.
        check_case("T08: MEM and WB both match rs1",
                   1, 1, 5'd11, 5'd2, 5'd11, 5'd11,
                   FWD_MEM, FWD_NONE);

        check_case("T09: MEM and WB both match rs2",
                   1, 1, 5'd2, 5'd12, 5'd12, 5'd12,
                   FWD_NONE, FWD_MEM);

        // Different producers match different source operands.
        check_case("T10: MEM matches rs1, WB matches rs2",
                   1, 1, 5'd13, 5'd14, 5'd13, 5'd14,
                   FWD_MEM, FWD_WB);

        check_case("T11: WB matches rs1, MEM matches rs2",
                   1, 1, 5'd15, 5'd16, 5'd16, 5'd15,
                   FWD_WB, FWD_MEM);

        // Register x0 must never trigger forwarding, even if addresses match.
        check_case("T12: MEM destination is x0",
                   1, 0, 5'd0, 5'd3, 5'd0, 5'd8,
                   FWD_NONE, FWD_NONE);

        check_case("T13: WB destination is x0",
                   0, 1, 5'd0, 5'd3, 5'd8, 5'd0,
                   FWD_NONE, FWD_NONE);

        check_case("T14: both destinations x0",
                   1, 1, 5'd0, 5'd0, 5'd0, 5'd0,
                   FWD_NONE, FWD_NONE);

        // Equal register numbers are not enough: corresponding write-enable must be high.
        check_case("T15: address matches but MEM WE off",
                   0, 0, 5'd17, 5'd18, 5'd17, 5'd18,
                   FWD_NONE, FWD_NONE);

        // No matching producer.
        check_case("T16: no address match",
                   1, 1, 5'd19, 5'd20, 5'd21, 5'd22,
                   FWD_NONE, FWD_NONE);

        // Boundary register addresses.
        check_case("T17: highest register x31 matches MEM",
                   1, 0, 5'd31, 5'd1, 5'd31, 5'd2,
                   FWD_MEM, FWD_NONE);

        check_case("T18: highest register x31 matches WB",
                   0, 1, 5'd1, 5'd31, 5'd2, 5'd31,
                   FWD_NONE, FWD_WB);

        $display("===== forward_unit SUMMARY =====");
        $display("Total: %0d | Passed: %0d | Failed: %0d",
                 tests, tests - errors, errors);
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("RESULT: TESTS FAILED");
        $display("================================");
        if (errors != 0) $fatal(1, "forward_unit: %0d test(s) failed", errors);
        $finish;
    end
endmodule
