`timescale 1ns/1ps

module tb_seven_segment_led_ctrl;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic [31:0] counter_value = '0;
    logic [7:0] anode;
    logic [6:0] seg_out;
    integer tests = 0;
    integer failed = 0;

    seven_segments_led_ctrl #(
        .SCAN_DIV_BITS(1)
    ) dut (
        .sys_clk(clk),
        .sys_rst_n(rst_n),
        .counter_value(counter_value),
        .anode(anode),
        .seg_out(seg_out)
    );

    always #5 clk = ~clk;

    function automatic logic [6:0] encode_digit(input logic [3:0] digit);
        case (digit)
            4'd0: encode_digit = 7'b0000001;
            4'd1: encode_digit = 7'b1001111;
            4'd2: encode_digit = 7'b0010010;
            4'd3: encode_digit = 7'b0000110;
            4'd4: encode_digit = 7'b1001100;
            4'd5: encode_digit = 7'b0100100;
            4'd6: encode_digit = 7'b0100000;
            4'd7: encode_digit = 7'b0001111;
            4'd8: encode_digit = 7'b0000000;
            4'd9: encode_digit = 7'b0000100;
            default: encode_digit = 7'b1111111;
        endcase
    endfunction

    task automatic check_display(input logic [31:0] value);
        logic [3:0] expected_digit;
        integer sample;
        begin
            @(negedge clk);
            counter_value = value;

            for (sample = 0; sample < 16; sample++) begin
                @(posedge clk);
                #1;
                tests++;
                case (anode)
                    8'b1111_1110: expected_digit = (value / 1) % 10;
                    8'b1111_1101: expected_digit = (value / 10) % 10;
                    8'b1111_1011: expected_digit = (value / 100) % 10;
                    8'b1111_0111: expected_digit = (value / 1000) % 10;
                    default: begin
                        expected_digit = 4'hF;
                        failed++;
                        $display("[FAIL] invalid active anode %b", anode);
                    end
                endcase
                if ((anode[7:4] !== 4'b1111) ||
                    (seg_out !== encode_digit(expected_digit))) begin
                    failed++;
                    $display("[FAIL] value=%0d anode=%b seg=%b expected digit=%0d",
                             value, anode, seg_out, expected_digit);
                end
            end
            $display("[DONE] checked display value %0d", value);
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        check_display(32'd1234);
        check_display(32'd9999);
        check_display(32'd10000);
        check_display(32'hFFFF_FFFF);

        if (failed == 0)
            $display("RESULT: ALL %0d DISPLAY CHECKS PASSED", tests);
        else
            $fatal(1, "seven-segment controller: %0d of %0d checks failed",
                   failed, tests);
        $finish;
    end
endmodule
