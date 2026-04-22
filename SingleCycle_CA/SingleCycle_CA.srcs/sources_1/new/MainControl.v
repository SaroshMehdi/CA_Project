`timescale 1ns / 1ps
module MainControl(
    input  wire [6:0] opcode,
    output reg        Branch,
    output reg        MemRead,
    output reg        MemtoReg,
    output reg  [1:0] ALUOp,
    output reg        MemWrite,
    output reg        ALUSrc,
    output reg        RegWrite,
    output reg        Jump,
    output reg        Jalr
);
    always @(*) begin
        RegWrite = 0; ALUSrc = 0; MemRead = 0;
        MemWrite = 0; MemtoReg = 0; Branch = 0;
        Jump = 0; Jalr = 0;
        ALUOp = 2'b00;
        case(opcode)
            7'b0110011: begin // R-type
                RegWrite = 1'b1; ALUOp = 2'b10;
            end
            7'b0010011: begin // I-type (ADDI)
                RegWrite = 1'b1; ALUSrc = 1'b1; ALUOp = 2'b11;
            end
            7'b0000011: begin // Load
                RegWrite = 1'b1; ALUSrc = 1'b1;
                MemRead = 1'b1; MemtoReg = 1'b1; ALUOp = 2'b00;
            end
            7'b0100011: begin // Store
                ALUSrc = 1'b1; MemWrite = 1'b1; ALUOp = 2'b00;
            end
            7'b1100011: begin // Branch (BEQ, BNE)
                Branch = 1'b1; ALUOp = 2'b01;
            end
            7'b1101111: begin // JAL
                RegWrite = 1'b1; Jump = 1'b1;
            end
            7'b1100111: begin // JALR
                RegWrite = 1'b1; Jalr = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule