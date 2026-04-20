`timescale 1ns / 1ps
module DataMemory (
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);
    reg [31:0] memory [0:511];
    always @(posedge clk) begin
        if (MemWrite)
            memory[address[8:0]] <= write_data;
    end
    always @(*) begin
        if (MemRead)
            read_data = memory[address[8:0]];
        else
            read_data = 32'd0;
    end
endmodule