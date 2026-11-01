module seven_segments_led_ctrl #(
    parameter integer SCAN_DIV_BITS = 14
) (
    input  logic        sys_clk,
    input  logic        sys_rst_n,
    input  logic [31:0] counter_value,
    output logic [7:0]  anode,
    output logic [6:0]  seg_out
);
    logic [SCAN_DIV_BITS+1:0] scan_counter;
    logic [1:0] digit_select;
    logic [39:0] bcd_value;
    logic [3:0] selected_digit;
    integer bit_index;
    integer digit_index;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            scan_counter <= '0;
        else
            scan_counter <= scan_counter + 1'b1;
    end

    assign digit_select = scan_counter[SCAN_DIV_BITS+1:SCAN_DIV_BITS];

    always_comb begin
        bcd_value = '0;
        for (bit_index = 31; bit_index >= 0; bit_index = bit_index - 1) begin
            for (digit_index = 0; digit_index < 10; digit_index = digit_index + 1) begin
                if (bcd_value[digit_index*4 +: 4] >= 4'd5)
                    bcd_value[digit_index*4 +: 4] =
                        bcd_value[digit_index*4 +: 4] + 4'd3;
            end
            bcd_value = {bcd_value[38:0], counter_value[bit_index]};
        end
    end

    always_comb begin
        anode = 8'b1111_1111;
        selected_digit = 4'd0;

        case (digit_select)
            2'd0: begin
                anode[0] = 1'b0;
                selected_digit = bcd_value[3:0];
            end
            2'd1: begin
                anode[1] = 1'b0;
                selected_digit = bcd_value[7:4];
            end
            2'd2: begin
                anode[2] = 1'b0;
                selected_digit = bcd_value[11:8];
            end
            2'd3: begin
                anode[3] = 1'b0;
                selected_digit = bcd_value[15:12];
            end
            default: begin
                anode = 8'b1111_1111;
                selected_digit = 4'd0;
            end
        endcase

        case (selected_digit)
            4'd0: seg_out = 7'b0000001;
            4'd1: seg_out = 7'b1001111;
            4'd2: seg_out = 7'b0010010;
            4'd3: seg_out = 7'b0000110;
            4'd4: seg_out = 7'b1001100;
            4'd5: seg_out = 7'b0100100;
            4'd6: seg_out = 7'b0100000;
            4'd7: seg_out = 7'b0001111;
            4'd8: seg_out = 7'b0000000;
            4'd9: seg_out = 7'b0000100;
            default: seg_out = 7'b1111111;
        endcase
    end
endmodule
