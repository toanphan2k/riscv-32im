//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-23
// Design Name:
// Module Name: fpga_top
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the fpga_top module.
//
// Dependencies:
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module fpga_top #(
    parameter       MEM_FILE   = "test.mem"
)(
    input  logic        sys_clk,    // E3
    input  logic        sys_rst_n,

    // External GPIO outputs (LED)
    output logic [7:0] anode,    // AN0 - AN8
    output logic [6:0] seg_out   // CA, CB, CC, CD, CE, CF, CG, DP (DP not need yet)
);
    logic [31:0]    gpio_out;
    logic [1:0]     rst_sync_q;
    logic           rst_n_sync;

    // asynchronous-assertion, synchronous-deassertion reset synchronizer
    always_ff @( posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n) begin
            rst_sync_q <= 2'b00;
        end else begin
            rst_sync_q <= {rst_sync_q[0], 1'b1};
        end
    end

    assign rst_n_sync = rst_sync_q[1];

    cpu_rv32im_top #(
        .HEX_FILE(MEM_FILE)
    ) cpu_u (
        .clk(sys_clk),
        .rst_n(rst_n_sync),
        .gpio_out(gpio_out)
    );

    always_comb begin
        anode = 8'b11111111; // Disable all anodes
        seg_out = 7'b1111111; // Turn off all segments

        // Active-low segment outputs ordered as {CA, CB, CC, CD, CE, CF, CG}.
        case (gpio_out[3:0])
            4'h0: seg_out = 7'b0000001;
            4'h1: seg_out = 7'b1001111;
            4'h2: seg_out = 7'b0010010;
            4'h3: seg_out = 7'b0000110;
            4'h4: seg_out = 7'b1001100;
            4'h5: seg_out = 7'b0100100;
            4'h6: seg_out = 7'b0100000;
            4'h7: seg_out = 7'b0001111;
            4'h8: seg_out = 7'b0000000;
            4'h9: seg_out = 7'b0000100;
            default: seg_out = 7'b1111111;
        endcase

        anode = 8'b11111110; // Enable AN0 (active-low)
    end

endmodule