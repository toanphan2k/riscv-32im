import rv32im_pkg::*;

module cla_32bit_benchmark_top (
    input  logic [XLEN-1:0] a,
    input  logic [XLEN-1:0] b,
    input  logic            sub_en,
    output logic [XLEN-1:0] result,
    output logic            cout,
    output logic            overflow,
    output logic            zero,
    output logic            negative
);
    cla_32bit dut (
        .a        (a),
        .b        (b),
        .sub_en   (sub_en),
        .result   (result),
        .cout     (cout),
        .overflow (overflow),
        .zero     (zero),
        .negative (negative)
    );
endmodule
