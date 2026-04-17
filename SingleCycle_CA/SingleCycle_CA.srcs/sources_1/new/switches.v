`timescale 1ns / 1ps
module switches(
    input  wire        clk, rst,
    input  wire [15:0] btns,
    input  wire [31:0] writeData,
    input  wire        writeEnable,
    input  wire        readEnable,
    input  wire [29:0] memAddress,
    input  wire [15:0] switches,
    output reg  [31:0] readData
);

    reg [7:0] switchData [3:0]; 
    localparam [29:0] SW_ADDR = 30'h00000001;

    always @(posedge clk) begin
        if (rst) begin
            readData <= 32'd0;
            switchData[0] <= 8'd0;
            switchData[1] <= 8'd0;
            switchData[2] <= 8'd0;
            switchData[3] <= 8'd0;
        end else begin
            switchData[0] <= switches[7:0];
            switchData[1] <= switches[15:8];
            switchData[2] <= 8'd0;
            switchData[3] <= 8'd0;
            
            if (readEnable && memAddress == SW_ADDR)
                readData <= {16'd0, switches};
            else
                readData <= 32'd0;
        end
    end
endmodule