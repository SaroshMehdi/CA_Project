`timescale 1ns / 1ps
module SingleCycle(
    input wire clk,
    input wire rst,
    
    output wire [31:0] pc_out,
    output wire [31:0] alu_result_out
);
    
    // Internal wires - PC path
    wire [31:0] PC, PC_Next, PC_Plus4;
    wire [31:0] instruction;
    
    // Internal wires - Control signals
    wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite;
    wire [1:0] ALUOp;
    wire [3:0] ALU_Ctrl_Signal;
    wire PCSrc;
    
    // Internal wires - Datapath
    wire [31:0] imm;
    wire [31:0] readData1, readData2, WriteData;
    wire [31:0] ALU_B, ALUResult;
    wire Zero;
    wire [31:0] mem_read_data;
    wire [31:0] BranchTarget;
    
    //----------------------------------------------------------
    // FETCH STAGE
    //----------------------------------------------------------
    
    ProgCounter u_PC (
        .clk(clk),
        .rst(rst),
        .PC_Next(PC_Next),
        .PC(PC)
    );

    PcAdd4 u_PA4 (
        .PC(PC),
        .PC_Plus4(PC_Plus4)
    );

    instructionMemory u_IM (
        .instAddress(PC),
        .instruction(instruction)
    );

    //----------------------------------------------------------
    // DECODE STAGE
    //----------------------------------------------------------

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

    ImmGen u_ImmG (
        .instruction(instruction),
        .imm(imm)
    );

    //----------------------------------------------------------
    // EXECUTE STAGE
    //----------------------------------------------------------

    ALUControl u_ALUCon (
        .ALUOp(ALUOp),
        .funct3(instruction[14:12]),
        .funct7(instruction[31:25]),
        .ALUControl(ALU_Ctrl_Signal)
    );

    Mux2x1 u_ALUSrcMux (
        .in0(readData2),
        .in1(imm),
        .sel(ALUSrc),
        .out(ALU_B)
    );

    ALU u_ALU (
        .A(readData1),
        .B(ALU_B),
        .ALUControl(ALU_Ctrl_Signal),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    BranchAdder u_BA (
        .PC(PC),
        .imm(imm),
        .BranchTarget(BranchTarget)
    );

    // Branch is taken only when Branch control is high and ALU result is zero
    assign PCSrc = Branch & Zero;

    Mux2x1 u_PCMux (
        .in0(PC_Plus4),
        .in1(BranchTarget),
        .sel(PCSrc),
        .out(PC_Next)
    );

    //----------------------------------------------------------
    // MEMORY STAGE
    //----------------------------------------------------------

    DataMemory u_DataMem (
        .clk(clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .address(ALUResult[10:2]),
        .write_data(readData2),
        .read_data(mem_read_data)
    );

    //----------------------------------------------------------
    // WRITEBACK STAGE
    //----------------------------------------------------------

    Mux2x1 u_MemtoRegMux (
        .in0(ALUResult),
        .in1(mem_read_data),
        .sel(MemtoReg),
        .out(WriteData)
    );

    assign pc_out = PC;
    assign alu_result_out = ALUResult;

endmodule