//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Toan Phan Minh
//
// Create Date: 2026-10-22
// Design Name:
// Module Name: rv32im_core
// Project Name: riscv-32im
// Target Devices:
// Tool Versions:
// Description: SystemVerilog implementation of the rv32im_core module.
//
// Dependencies: rv32im_pkg.sv
//
// Revision: 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

import rv32im_pkg::*;

module rv32im_core #(
    parameter logic [XLEN-1:0] RESET_SP = '0
) (
    // Clock and Reset
    input  logic clk,
    input  logic rst_n,
    // Instruction Memory Interface
    input  logic [XLEN-1:0] imem_rdata,
    output logic [XLEN-1:0] imem_addr,
    output logic            imem_req,
    // Data Memory Interface
    input  logic [XLEN-1:0] dmem_rdata,
    output logic [XLEN-1:0] dmem_addr,
    output logic [3:0]      dmem_wstrobe,
    output logic            dmem_req,
    output logic            dmem_en_write,
    output logic [XLEN-1:0] dmem_wdata
);

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------

    // Harzard unit output signals
    logic if_pc_en;
    logic stall_if_id,  flush_if_id;
    logic stall_id_ex,  flush_id_ex;
    logic stall_ex_mem, flush_ex_mem;
    logic stall_mem_wb, flush_mem_wb;

    // Output Forwarding Unit Select
    fwd_sel_e    fwd_a, fwd_b;

    // IF stage output signal
    logic [XLEN-1:0]    if_pc;
    logic [XLEN-1:0]    if_pc4;
    logic               is_fetch_valid;

    // IF/ID Reg outputs
    logic [XLEN-1:0]    id_instr;
    logic [XLEN-1:0]    id_pc4;
    logic [XLEN-1:0]    id_pc;

    // ID stage output signals
    ctrl_signal_t       id_ctrl;
    logic [XLEN-1:0]    id_imm;
    logic [XLEN-1:0]    id_out_pc;
    logic [XLEN-1:0]    id_out_pc4;
    logic [XLEN-1:0]    id_rs1_data;
    logic [XLEN-1:0]    id_rs2_data;
    logic [REG_ADDR_WIDTH-1:0]   id_rs1_addr;
    logic [REG_ADDR_WIDTH-1:0]   id_rs2_addr;
    logic [REG_ADDR_WIDTH-1:0]   id_rd_addr;

    // ID/EX Reg outputs
    ctrl_signal_t               ex_ctrl;
    logic [XLEN-1:0]            ex_pc;
    logic [XLEN-1:0]            ex_pc4;
    logic [XLEN-1:0]            ex_imm;
    logic [XLEN-1:0]            ex_rs1_data;
    logic [XLEN-1:0]            ex_rs2_data;
    logic [REG_ADDR_WIDTH-1:0]  ex_rs1_addr;
    logic [REG_ADDR_WIDTH-1:0]  ex_rs2_addr;
    logic [REG_ADDR_WIDTH-1:0]  ex_rd_addr;

    // Stage EX output signals
    ctrl_signal_t               ex_out_ctrl;
    logic [XLEN-1:0]            ex_out_pc4;
    logic [XLEN-1:0]            ex_out_alu_result;
    logic [XLEN-1:0]            ex_out_m_unit_result;
    logic [XLEN-1:0]            ex_out_rs2_data;
    logic [REG_ADDR_WIDTH-1:0]  ex_out_rd_addr;
    logic                       branch_taken;
    logic [XLEN-1:0]            branch_target_addr;
    logic                       m_unit_busy;

    // EX/MEM Reg outputs
    ctrl_signal_t               mem_ctrl;
    logic [XLEN-1:0]            mem_pc4;
    logic [XLEN-1:0]            mem_alu_result;
    logic [XLEN-1:0]            mem_m_unit_result;
    logic [XLEN-1:0]            mem_rs2_data;
    logic [REG_ADDR_WIDTH-1:0]  mem_rd_addr;


    // Stage MEM output signals
    ctrl_signal_t               mem_out_ctrl;
    logic [XLEN-1:0]            mem_out_alu_result;
    logic [XLEN-1:0]            mem_out_m_unit_result;
    logic [XLEN-1:0]            mem_out_pc4;
    logic [XLEN-1:0]            mem_fwd_data;
    logic [REG_ADDR_WIDTH-1:0]  mem_out_rd_addr;

    // MEM/WB Reg outputs
    ctrl_signal_t               wb_ctrl;
    logic [XLEN-1:0]            wb_pc4;
    logic [XLEN-1:0]            wb_alu_result;
    logic [XLEN-1:0]            wb_m_unit_result;
    logic [REG_ADDR_WIDTH-1:0]  wb_rd_addr;

    // Stage WB output signals
    logic [XLEN-1:0]            wb_data;
    logic                       wb_en_reg_write;
    logic [REG_ADDR_WIDTH-1:0]  wb_out_rd_addr;

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    stage_if stage_if_u (
        .clk(clk),
        .rst_n(rst_n),
        .pc_en(if_pc_en),
        .pc_src_sel(branch_taken),
        .pc(if_pc),
        .pc4(if_pc4),
        .branch_target(branch_target_addr),
        .is_fetch_valid(is_fetch_valid),
        .imem_addr(imem_addr),
        .imem_read_req(imem_req)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    reg_if_id if_id_reg (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_if_id),
        .flush(flush_if_id || !is_fetch_valid),
        .if_instr(imem_rdata),
        .if_pc(if_pc),
        .if_pc4(if_pc4),
        .id_instr(id_instr),
        .id_pc(id_pc),
        .id_pc4(id_pc4)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    stage_id #(
        .RESET_SP(RESET_SP)
    ) stage_id_u (
        .clk(clk),
        .rst_n(rst_n),
        .id_pc(id_pc),
        .id_pc4(id_pc4),
        .id_instr(id_instr),
        .wb_en_reg_write(wb_en_reg_write),
        .wb_data(wb_data),
        .wb_rd_addr(wb_out_rd_addr),
        .id_ctrl(id_ctrl),
        .id_imm(id_imm),
        .id_out_pc(id_out_pc),
        .id_out_pc4(id_out_pc4),
        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .id_rd_addr(id_rd_addr)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    reg_id_ex id_ex_reg (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_id_ex),
        .flush(flush_id_ex),
        .id_ctrl(id_ctrl),
        .id_pc(id_out_pc),
        .id_pc4(id_out_pc4),
        .id_imm(id_imm),
        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .id_rd_addr(id_rd_addr),
        .ex_ctrl(ex_ctrl),
        .ex_pc(ex_pc),
        .ex_pc4(ex_pc4),
        .ex_imm(ex_imm),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        .ex_rd_addr(ex_rd_addr)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    stage_ex stage_ex_u (
        .clk(clk),
        .rst_n(rst_n),
        .ex_in_ctrl(ex_ctrl),
        .ex_pc(ex_pc),
        .ex_pc4(ex_pc4),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_imm(ex_imm),
        .ex_rd_addr(ex_rd_addr),
        .sel_a(fwd_a),
        .sel_b(fwd_b),
        .fwd_mem_data(mem_fwd_data),
        .fwd_wb_data(wb_data),
        .ex_out_ctrl(ex_out_ctrl),
        .ex_out_pc4(ex_out_pc4),
        .ex_out_alu_result(ex_out_alu_result),
        .ex_out_m_unit_result(ex_out_m_unit_result),
        .ex_out_rs2_data(ex_out_rs2_data),
        .ex_out_rd_addr(ex_out_rd_addr),
        .branch_taken(branch_taken),
        .branch_target_addr(branch_target_addr),
        .m_unit_busy(m_unit_busy)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    reg_ex_mem ex_mem_reg (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_ex_mem),
        .flush(flush_ex_mem),
        .ex_ctrl(ex_out_ctrl),
        .ex_pc4(ex_out_pc4),
        .ex_alu_result(ex_out_alu_result),
        .ex_m_unit_result(ex_out_m_unit_result),
        .ex_rs2_data(ex_out_rs2_data),
        .ex_rd_addr(ex_out_rd_addr),
        .mem_ctrl(mem_ctrl),
        .mem_pc4(mem_pc4),
        .mem_alu_result(mem_alu_result),
        .mem_m_unit_result(mem_m_unit_result),
        .mem_rs2_data(mem_rs2_data),
        .mem_rd_addr(mem_rd_addr)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    stage_mem stage_mem_u (
        .mem_ctrl(mem_ctrl),
        .mem_alu_result(mem_alu_result),
        .mem_m_unit_result(mem_m_unit_result),
        .mem_rs2_data(mem_rs2_data),
        .mem_pc4(mem_pc4),
        .mem_rd_addr(mem_rd_addr),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_wstrobe(dmem_wstrobe),
        .dmem_req(dmem_req),
        .en_dmem_write(dmem_en_write),
        .mem_out_ctrl(mem_out_ctrl),
        .mem_out_alu_result(mem_out_alu_result),
        .mem_out_m_unit_result(mem_out_m_unit_result),
        .mem_out_pc4(mem_out_pc4),
        .mem_out_rd_addr(mem_out_rd_addr),
        .mem_fwd_data(mem_fwd_data)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    reg_mem_wb mem_wb_reg (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_mem_wb),
        .flush(flush_mem_wb),
        .mem_ctrl(mem_out_ctrl),
        .mem_alu_result(mem_out_alu_result),
        .mem_m_unit_result(mem_out_m_unit_result),
        .mem_pc4(mem_out_pc4),
        .mem_rd_addr(mem_out_rd_addr),
        .wb_ctrl(wb_ctrl),
        .wb_alu_result(wb_alu_result),
        .wb_m_unit_result(wb_m_unit_result),
        .wb_pc4(wb_pc4),
        .wb_rd_addr(wb_rd_addr)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    stage_wb stage_wb_u (
        .wb_ctrl(wb_ctrl),
        .wb_alu_result(wb_alu_result),
        .wb_m_unit_result(wb_m_unit_result),
        .dmem_rdata(dmem_rdata),
        .wb_pc4(wb_pc4),
        .wb_rd_addr(wb_rd_addr),
        .wb_en_reg_write(wb_en_reg_write),
        .wb_data(wb_data),
        .wb_out_rd_addr(wb_out_rd_addr)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------s
    forward_unit forward_u (
        .mem_rd_wren(mem_ctrl.en_reg_write),
        .mem_rd_addr(mem_rd_addr),
        .wb_rd_wren(wb_en_reg_write),
        .wb_rd_addr(wb_out_rd_addr),
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        .fwd_a(fwd_a),
        .fwd_b(fwd_b)
    );

    //-------------------------------------------------
    // Signal interconnects
    //-------------------------------------------------
    harzard_unit harzard_u (
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .ex_rd_addr(ex_rd_addr),
        .branch_taken(branch_taken),
        .m_busy(m_unit_busy),
        .ex_ctrl(ex_ctrl),
        .id_ctrl(id_ctrl),
        .if_pc_en(if_pc_en),
        .stall_if_id(stall_if_id),
        .stall_id_ex(stall_id_ex),
        .stall_ex_mem(stall_ex_mem),
        .stall_mem_wb(stall_mem_wb),
        .flush_if_id(flush_if_id),
        .flush_id_ex(flush_id_ex),
        .flush_ex_mem(flush_ex_mem),
        .flush_mem_wb(flush_mem_wb)
    );

endmodule
