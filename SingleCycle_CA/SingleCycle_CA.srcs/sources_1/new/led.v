`timescale 1ns / 1ps

module leds(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] writeData,
    input  wire        writeEnable,
    input  wire        readEnable,
    input  wire [29:0] memAddress,
    output reg  [31:0] readData = 0, // not to be read       
    output reg  [15:0] leds
);

    reg [7:0] ledData [3:0];
    localparam [29:0] LED_ADDR = 30'h00000002;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            leds <= 16'd0;
            for (i = 0; i < 4; i = i + 1)
                ledData[i] <= 8'd0;
        end else begin
            // When the Top Module asks to write to the LEDs, update them!
            if (writeEnable && memAddress == LED_ADDR) begin
                ledData[0] <= writeData[7:0];
                ledData[1] <= writeData[15:8];
                ledData[2] <= writeData[23:16];
                ledData[3] <= writeData[31:24];
                leds <= writeData[15:0];
            end
        end
    end
endmodule