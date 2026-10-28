//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-18
// Design Name:
// Module Name: cpu_rv32im_top
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the cpu_rv32im_top module.
//
// Dependencies:
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module cpu_rv32im_top #(
    parameter int   DATA_WIDTH = 32,
    parameter int   ADDR_WIDTH = 12,
    parameter       HEX_FILE = "test.mem"
)(
    input  logic        clk,
    input  logic        rst_n,

    // External GPIO outputs (LED)
    output logic [31:0] gpio_out
);
    // Init Reset Stack Pointer to 0x4000
    localparam logic [DATA_WIDTH-1:0] RESET_SP =  (1 << (ADDR_WIDTH + 2));

    logic [DATA_WIDTH-1:0] imem_addr;
    logic [DATA_WIDTH-1:0] dmem_addr;

    logic [ADDR_WIDTH-1:0] rom_addr;
    logic [ADDR_WIDTH-1:0] ram_addr;

    logic imem_req;
    logic dmem_req;
    logic ram_req;
    logic dmem_en_write;
    logic [3:0] wstrobe;

    logic [DATA_WIDTH-1:0] imem_rdata;
    logic [DATA_WIDTH-1:0] dmem_rdata;
    logic [DATA_WIDTH-1:0] dmem_wdata;
    logic [DATA_WIDTH-1:0] ram_rdata;

    // Memory Mapping Input Output match address and register
    logic is_mmio;
    logic is_mmio_q;
    logic [DATA_WIDTH-1:0] mmio_rdata;
    logic [DATA_WIDTH-1:0] mmio_rdata_q;
    logic [63:0] cycle_cnt_reg;
    logic [31:0] gpio_reg;

    // Check address of DMEM
    // is_mmio -> mapping to GPIO
    // Addr <  0x8000_0000 -> RAM
    // Addr >= 0x8000_0000 -> MMIO
    assign is_mmio = dmem_addr[31];
    assign ram_req = dmem_req && !is_mmio;

    assign rom_addr = imem_addr[ADDR_WIDTH+1:2];
    assign ram_addr = dmem_addr[ADDR_WIDTH+1:2];

    always_ff @(posedge clk or negedge rst_n) begin : GPIO_REG
        if(!rst_n) begin
            gpio_reg <= '0;
        end else begin
            if(dmem_req && dmem_en_write && is_mmio) begin
                case(dmem_addr[7:0])
                    8'h00:   gpio_reg <= dmem_wdata;
                    default: ;
                endcase
            end
        end
    end

    assign gpio_out = gpio_reg;

    // TEMP SOLUTION since there is no CSR
    always_ff @(posedge clk or negedge rst_n) begin : CYCLE_COUNTER
        if(!rst_n) begin
            cycle_cnt_reg <= '0;
        end else begin
            cycle_cnt_reg <= cycle_cnt_reg + 64'd1;
        end
    end

    always_comb begin : MMIO_READ_MUX
        case(dmem_addr[7:0])
            8'h00:   mmio_rdata = gpio_reg;
            8'h08:   mmio_rdata = cycle_cnt_reg[31:0];
            8'h0C:   mmio_rdata = cycle_cnt_reg[63:32];
            default: mmio_rdata = '0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin : MMIO_DATA_REG
        if (!rst_n) begin
            is_mmio_q    <= '0;
            mmio_rdata_q <= '0;
        end else begin
            mmio_rdata_q <= mmio_rdata;
            is_mmio_q    <= is_mmio;
        end
    end


    assign dmem_rdata = is_mmio_q ? mmio_rdata_q : ram_rdata;

    rv32im_core #(
        .RESET_SP(RESET_SP)
    ) rv32im_core_u (
        .clk(clk),
        .rst_n(rst_n),
        .imem_rdata(imem_rdata),
        .imem_addr(imem_addr),
        .imem_req(imem_req),
        .dmem_rdata(dmem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wstrobe(wstrobe),
        .dmem_req(dmem_req),
        .dmem_en_write(dmem_en_write),
        .dmem_wdata(dmem_wdata)
    );

    instruction_rom #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .HEX_FILE(HEX_FILE)
    ) instruction_mem (
        .clk(clk),
        .en_read(imem_req),
        .raddr(rom_addr),
        .rdata(imem_rdata)
    );

    single_port_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) data_mem (
        .clk(clk),
        .en_write(dmem_en_write),
        .req(ram_req),
        .wstrobe(wstrobe),
        .addr(ram_addr),
        .wdata(dmem_wdata),
        .rdata(ram_rdata)
    );

endmodule
