module seven_segments_led_ctrl (
    input  logic        sys_clk,    // E3
    input  logic        sys_rst_n,

    // External GPIO outputs (LED)
    output logic [7:0] anode,    // AN0 - AN8
    output logic [6:0] seg_out   // CA, CB, CC, CD, CE, CF, CG, DP (DP not need yet)
);

    assign anode = 8'b0000_0000; // Turn on the first anode (AN0) and turn off the rest
    assign seg_out = 7'b1111001; // Display the number '0' on the 7-segment display
endmodule
