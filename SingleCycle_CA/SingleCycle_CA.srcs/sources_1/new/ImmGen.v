`timescale 1ns / 1ps
module ImmGen(
    input  wire [31:0] instruction,
    output reg  [31:0] imm
);
    wire [6:0] opcode = instruction[6:0];
    always @(*) begin
        case(opcode)
            // I-Type (ADDI, LW, JALR)
            7'b0010011, 7'b0000011, 7'b1100111:
                imm = {{20{instruction[31]}}, instruction[31:20]};
            // S-Type (SW)
            7'b0100011:
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            // B-Type (BEQ, BNE) - appends 1'b0, BranchAdder does PC+imm directly
            7'b1100011:
                imm = {{20{instruction[31]}}, instruction[7],
                        instruction[30:25], instruction[11:8], 1'b0};
            // J-Type (JAL)
            7'b1101111:
                imm = {{12{instruction[31]}}, instruction[19:12],
                        instruction[20], instruction[30:21], 1'b0};
            // U-Type (LUI)
            7'b0110111:
                imm = {instruction[31:12], 12'b0};
            default: imm = 32'd0;
        endcase
    end
endmodule