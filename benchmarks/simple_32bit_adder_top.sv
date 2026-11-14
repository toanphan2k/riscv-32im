import rv32im_pkg::*;

module simple_32bit_adder_benchmark_top (
    input  logic [XLEN-1:0] a,
    input  logic [XLEN-1:0] b,
    input  logic            sub_en,
    output logic [XLEN-1:0] result,
    output logic            cout,
    output logic            overflow,
    output logic            zero,
    output logic            negative
);
    simple_32bit_adder dut (
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
