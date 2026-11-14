import rv32im_pkg::*;

module simple_divider_benchmark_top (
    input  logic [XLEN-1:0] operand_a,
    input  logic [XLEN-1:0] operand_b,
    input  m_ext_opcode_e   m_opcode,
    output logic [XLEN-1:0] div_result
);
    simple_divider dut (
        .operand_a  (operand_a),
        .operand_b  (operand_b),
        .m_opcode   (m_opcode),
        .div_result (div_result)
    );
endmodule
