`timescale 1ns/1ps

module tb_radix4_nonres_divider;
    tb_radix_divider_test_runner #(.DIVIDER_KIND(2)) test_runner();
endmodule
