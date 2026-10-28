//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-13
// Design Name:
// Module Name: single_port_ram
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the single_port_ram module.
//
// Dependencies:
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

// BLOCK RAM
module single_port_ram #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 12
)
(
    input  logic clk,
    input  logic en_write,
    input  logic req,
    input  logic [3:0] wstrobe,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata
);
    // DEPTH = 1 << ADDR_WIDTH; DEPTH = 2^ADDR_WIDTH; DEPTH = 4096
    // 4096 Storage location for 32 bit data
    // 4096 * 4 bytes = 16384 bytes of storage
    // 16384 bytes of storage
    localparam int DEPTH = 1 << ADDR_WIDTH;
    logic [DATA_WIDTH-1:0] ram [0:DEPTH-1];

    // Synchronous Read/Write
    always_ff @(posedge clk) begin : SYNC_READ_WRITE_RAM
        if (req) begin
            rdata <= ram[addr];
            if (en_write) begin
                // if (wstrobe[0]) ram[addr][7:0]   <= wdata[7:0];
                // if (wstrobe[1]) ram[addr][15:8]  <= wdata[15:8];
                // if (wstrobe[2]) ram[addr][23:16] <= wdata[23:16];
                // if (wstrobe[3]) ram[addr][31:24] <= wdata[31:24];
                for (int i = 0; i < 4; i++) begin
                    if (wstrobe[i]) begin
                        ram[addr][(i*8)+:8] <= wdata[(i*8)+:8];
                    end
                end
            end
        end
    end

endmodule
