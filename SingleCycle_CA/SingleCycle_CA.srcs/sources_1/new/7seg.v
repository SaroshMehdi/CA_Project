`timescale 1ns / 1ps
module Seg7(
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] val,
    output reg  [6:0]  seg,
    output reg  [3:0]  an
);
    // Fast counter for multiplexing 3 displays
    reg [17:0] refresh_counter;
    always @(posedge clk or posedge rst) begin
        if (rst) refresh_counter <= 0;
        else     refresh_counter <= refresh_counter + 1;
    end
    wire [1:0] led_activation = refresh_counter[17:16];

    // Binary to Decimal (handles 0 to 999)
    wire [3:0] hundreds = (val / 100) % 10;
    wire [3:0] tens     = (val / 10)  % 10;
    wire [3:0] ones     =  val        % 10;

    reg [3:0] current_digit;

    // Multiplexing logic - 3 left-most digits
    always @(*) begin
        case(led_activation)
            2'b00: begin
                an = 4'b0111; // Hundreds
                current_digit = hundreds;
            end
            2'b01: begin
                an = 4'b1011; // Tens
                current_digit = tens;
            end
            2'b10: begin
                an = 4'b1101; // Ones
                current_digit = ones;
            end
            default: begin
                an = 4'b1111; // Rightmost digit OFF
                current_digit = 4'd0;
            end
        endcase
    end

    // Seven segment decoder
    always @(*) begin
        case(current_digit)
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule