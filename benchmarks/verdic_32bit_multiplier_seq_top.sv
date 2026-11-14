import rv32im_pkg::*;

module verdic_32bit_multiplier_seq_benchmark_top (
    input  logic            clk,
    input  logic            rst_n,
    input  logic            start,
    input  logic [XLEN-1:0] operand_a,
    input  logic [XLEN-1:0] operand_b,
    input  m_ext_opcode_e   m_opcode,
    output logic [XLEN-1:0] mul_result,
    output logic            is_busy,
    output logic            done
);
    verdic_32bit_multiplier_seq dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .operand_a  (operand_a),
        .operand_b  (operand_b),
        .m_opcode   (m_opcode),
        .mul_result (mul_result),
        .is_busy    (is_busy),
        .done       (done)
    );
endmodule
