`timescale 1ns / 1ps

module SingleCycle(
    input wire clk,
    input wire rst,
    
    output wire [31:0] pc_out,
    output wire [31:0] alu_result_out
);
    
    // PC & Instruction Wires
    wire [31:0] PC, PC_Next, PC_Plus4;
    wire [31:0] instruction;
    
    // Control Signal Wires
    wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
    wire [1:0] ALUOp;
    wire [3:0] ALU_Ctrl_Signal;
    wire PCSrc; // The AND gate output for branch decision
    
    // Register File & Immediate Wires
    wire [31:0] imm;
    wire [31:0] readData1, readData2, WriteData;
    
    // ALU Wires
    wire [31:0] ALU_B, ALUResult;
    wire Zero;
    
    // Memory & Branching Wires
    wire [31:0] mem_read_data;
    wire [31:0] BranchTarget;
    
    // 1. Program Counter
    ProgCounter u_PC (
        .clk(clk),
        .rst(rst),
        .PC_Next(PC_Next),
        .PC(PC)
    );

    // 2. PC Adder (PC + 4)
    PcAdd4 u_PA4 (
        .PC(PC),
        .PC_Plus4(PC_Plus4)
    );

    // 3. Instruction Memory
    instructionMemory u_IM (
        .instAddress(PC),
        .instruction(instruction)
    );

    // 4. Main Control Unit (Decodes opcode)
    MainControl u_MainControl (
        .opcode(instruction[6:0]),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite)
    );

    // 5. Register File
    RegisterFile u_RF (
        .clk(clk),
        .rst(rst),
        .WriteEnable(RegWrite),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),
        .WriteData(WriteData),
        .ReadData1(readData1),
        .ReadData2(readData2)
    );

    // 6. Immediate Generator
    ImmGen u_ImmG (
        .instruction(instruction),
        .imm(imm)
    );

    // 7. ALU Control Unit
    ALUControl u_ALUCon (
    .ALUOp(ALUOp),
    .funct3(instruction[14:12]),
    .funct7(instruction[31:25]),     // Full funct7 field [31:25]
    .ALUControl(ALU_Ctrl_Signal)
    );

    // 8. ALU Source Mux (Selection between rs2 and imm)
    Mux2x1 u_ALUSrcMux (
        .in0(readData2), // If ALUSrc=0, use register data
        .in1(imm),       // If ALUSrc=1, use immediate
        .sel(ALUSrc),
        .out(ALU_B)
    );

    // 9. Arithmetic Logic Unit (ALU)
    ALU u_ALU (
        .A(readData1),
        .B(ALU_B),
        .ALUControl(ALU_Ctrl_Signal),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    // 10. Branch Target Adder
    BranchAdder u_BA (
        .PC(PC),
        .imm(imm),
        .BranchTarget(BranchTarget)
    );

    // 11. Branch Decision AND Gate
    // PCSrc is only 1 if it's a Branch instruction AND the ALU says the registers are equal
    assign PCSrc = Branch & Zero;

    // 12. PC Source Multiplexer (Selects between PC+4 and Branch Target)
    Mux2x1 u_PCMux (
        .in0(PC_Plus4),
        .in1(BranchTarget),
        .sel(PCSrc),
        .out(PC_Next)
    );

    // 13. Data Memory (Using the updated 32-bit address version)
    DataMemory u_DataMem (
        .clk(clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .address(ALUResult[10:2]),     // ALU calculates the memory address
        .write_data(readData2),  // The data to store comes from rs2
        .read_data(mem_read_data)
    );

    // 14. Memory to Register Multiplexer
    Mux2x1 u_MemtoRegMux (
        .in0(ALUResult),      // If MemtoReg=0, write ALU result to register
        .in1(mem_read_data),  // If MemtoReg=1, write Memory data to register
        .sel(MemtoReg),
        .out(WriteData)
    
    );
    assign pc_out = PC;
    assign alu_result_out = ALUResult;

endmodule