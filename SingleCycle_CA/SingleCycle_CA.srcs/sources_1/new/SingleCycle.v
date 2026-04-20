`timescale 1ns / 1ps
module SingleCycle(
    input wire clk,
    input wire rst,
    input wire [15:0] switches,
    output wire [15:0] leds,
    output wire [6:0] seg,
    output wire [3:0] an
);

    // =========================================================
    // CLOCK DIVIDER (100MHz to 10MHz)
    // =========================================================
    reg [3:0] clk_div = 0;
    reg clk_10M = 0;
    
    always @(posedge clk) begin
        if (clk_div == 4) begin
            clk_div <= 0;
            clk_10M <= ~clk_10M;
        end else begin
            clk_div <= clk_div + 1;
        end
    end

    // PC & Instruction Wires
    wire [31:0] PC, PCNext, PCPlus4;
    wire [31:0] instruction;
    
    // Control Signal Wires
    wire Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite, Jump, Jalr, Lui;
    wire [1:0] ALUOp;
    wire [3:0] ALU_Ctrl_Signal;
    wire PCSrc;
    
    // Register File & Immediate Wires
    wire [31:0] imm;
    wire [31:0] readData1, readData2, WriteData;
    
    // ALU Wires
    wire [31:0] ALU_B, ALUResult;
    wire Zero;
    
    // Memory & Branching Wires
    wire [31:0] mem_read_data;
    wire [31:0] BranchTarget;
    wire [31:0] final_read_data;

    // =========================================================
    // DATAPATH INSTANTIATIONS
    // =========================================================
    
    ProgCounter u_PC (
        .clk(clk_10M),
        .rst(rst),
        .PCNext(PCNext),
        .PC(PC)
    );
    
    PcAdd4 u_pcAdd (
        .PC(PC),
        .PCPlus4(PCPlus4)
    );
    
    instructionMemory u_InstMem (
        .instAddress(PC),
        .instruction(instruction)
    );
    
    MainControl u_MainControl (
        .opcode(instruction[6:0]),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Jump(Jump),
        .Jalr(Jalr),
        .Lui(Lui)
    );
    
    RegisterFile u_RegFile (
        .clk(clk_10M),
        .rst(rst),
        .WriteEnable(RegWrite),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),
        .WriteData(WriteData),
        .readData1(readData1),
        .readData2(readData2)
    );
    
    ImmGen u_immGen (
        .instruction(instruction),
        .imm(imm)
    );
    
    ALUControl u_ALUControl (
        .ALUOp(ALUOp),
        .funct3(instruction[14:12]),
        .funct7_5(instruction[30]),
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
    
    BranchAdder u_brAdd (
        .PC(PC),
        .imm(imm),
        .BranchTarget(BranchTarget)
    );

    // =========================================================
    // BRANCH AND JUMP DATAPATH LOGIC
    // =========================================================
    wire is_BNE = (instruction[14:12] == 3'b001);
    assign PCSrc = (Branch & (is_BNE ? ~Zero : Zero)) | Jump;

    wire [31:0] PC_JumpBranch = PCSrc ? BranchTarget : PCPlus4;
    assign PCNext = Jalr ? (ALUResult & 32'hFFFFFFFE) : PC_JumpBranch;

    assign WriteData = (Jump | Jalr) ? PCPlus4  :
                       (Lui)         ? imm       :
                       (MemtoReg)    ? final_read_data :
                                       ALUResult;

    // =========================================================
    // ADDRESS DECODING & I/O
    // =========================================================
    // bits[9:8]==00 -> DataMemory
    // bits[9:8]==10 -> LEDs   (0x200 = 512)
    // bits[9:8]==11 -> Switches (0x300 = 768)

    wire LEDWrite = MemWrite & (ALUResult[9:8] == 2'b10);

    // Priority Encoder for switches
    wire [15:0] encoded_switches =
        switches[15] ? 16'd15 : switches[14] ? 16'd14 :
        switches[13] ? 16'd13 : switches[12] ? 16'd12 :
        switches[11] ? 16'd11 : switches[10] ? 16'd10 :
        switches[9]  ? 16'd9  : switches[8]  ? 16'd8  :
        switches[7]  ? 16'd7  : switches[6]  ? 16'd6  :
        switches[5]  ? 16'd5  : switches[4]  ? 16'd4  :
        switches[3]  ? 16'd3  : switches[2]  ? 16'd2  :
        switches[1]  ? 16'd1  : 16'd0;

    assign final_read_data = (ALUResult[9:8] == 2'b11) 
                             ? {16'd0, encoded_switches} 
                             : mem_read_data;

    DataMemory u_DataMem (
        .clk(clk_10M),
        .MemWrite(MemWrite & (ALUResult[9:8] == 2'b00)),
        .MemRead (MemRead  & (ALUResult[9:8] == 2'b00)),
        .address(ALUResult),
        .write_data(readData2),
        .read_data(mem_read_data)
    );

    // LED register
    reg [15:0] led_reg;
    always @(posedge clk_10M or posedge rst) begin
        if (rst)
            led_reg <= 16'd0;
        else if (LEDWrite)
            led_reg <= readData2[15:0];
    end
    assign leds = led_reg;

    // 7-seg shows live countdown value in decimal
    Seg7 u_7seg (
        .clk(clk),
        .rst(rst),
        .val(led_reg),
        .seg(seg),
        .an(an)
    );

endmodule