module Ctrl_Unit (
    input  wire [6:0] opcode_i,    // Instr[6:0]
    input  wire [2:0] func3_i,     // Instr[14:12]
    output reg        RegWrite_o,  //  regfile write
    output reg  [1:0] ResultSrc_o, // 00: ALU, 01: Mem, 10: PC+4, 11: U-type wb for register
    output reg  [3:0] MemWrite_o,  // (Store)
    output reg  [3:0] MemRead_o,   // (Load)
    output reg        Jump_o,      // flag JAL, JALR
    output reg        Jalr_o,      // JALR (RS1 + Imm)
    output reg        Branch_o,    // B-type
    output reg        ALUsrc_o,    //0: RS2, 1: Immediate
    output reg  [1:0] ALUop_o,     // sent to ALUctrl (00: Load/Store, 01: Branch, 10: R/I-type)
    output reg  [2:0] ImmSrc_o,    //  Immediate Extend
    output reg        ImmUI_o      // (1: LUI, 0: AUIPC)
);
    
    initial begin
        RegWrite_o  = 1'b0;
        ResultSrc_o = 2'b0;
        MemWrite_o  = 4'b0;
        MemRead_o   = 4'b0;
        Jump_o      = 1'b0;
        Jalr_o      = 1'b0;
        Branch_o    = 1'b0;
        ALUsrc_o    = 1'b0;
        ALUop_o     = 2'b0;
        ImmSrc_o    = 3'b0;
        ImmUI_o     = 1'b0;
    end

    always @(*) begin
        case(opcode_i)
            //  R-Type (ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU)
            7'b011_0011: begin
                RegWrite_o  = 1'b1;
                ResultSrc_o = 2'b00;   //  ALU
                MemWrite_o  = 4'b0000;
                MemRead_o   = 4'b0000;
                Jump_o      = 1'b0;
                Jalr_o      = 1'b0;
                Branch_o    = 1'b0;
                ALUsrc_o    = 1'b0;    // RS2
                ALUop_o     = 2'b10;   // decode func3, func7
                ImmSrc_o    = 3'bx;    //no Immediate
                ImmUI_o     = 1'bx;
            end

            // 2.  I-Type ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, SLTI, SLTIU)
            7'b001_0011: begin
                RegWrite_o  = 1'b1;
                ResultSrc_o = 2'b00;   // ALU
                MemWrite_o  = 4'b0000;
                MemRead_o   = 4'b0000;
                Jump_o      = 1'b0;
                Jalr_o      = 1'b0;
                Branch_o    = 1'b0;
                ALUsrc_o    = 1'b1;    // Immediate
                ALUop_o     = 2'b10;
                ImmUI_o     = 1'bx;
                case(func3_i)
                    3'b001:  ImmSrc_o = 3'b110; // SLLI (5 bit shamt)
                    3'b101:  ImmSrc_o = 3'b110; // SRLI, SRAI ( 5 bit shamt)
                    default: ImmSrc_o = 3'b001; // I-type signed 12bit
                endcase
            end

            //  I-Type Load (LB, LH, LW, LBU, LHU)
            7'b000_0011: begin
                RegWrite_o  = 1'b1;
                ResultSrc_o = 2'b01;   //  Data Memory
                MemWrite_o  = 4'b0000;
                Jump_o      = 1'b0;
                Jalr_o      = 1'b0;
                Branch_o    = 1'b0;
                ALUsrc_o    = 1'b1;    // RS1 + Offset
                ALUop_o     = 2'b00;
                ImmSrc_o    = 3'b001;  // Immediate I-type
                ImmUI_o     = 1'bx;
                case(func3_i)
                    3'b000:  MemRead_o = 4'b0001; // LB
                    3'b001:  MemRead_o = 4'b0010; // LH
                    3'b010:  MemRead_o = 4'b1000; // LW
                    3'b100:  MemRead_o = 4'b1001; // LBU
                    3'b101:  MemRead_o = 4'b1010; // LHU
                    default: MemRead_o = 4'b0000;
                endcase
            end

            // S-Type Store (SB, SH, SW)
            7'b010_0011: begin
                RegWrite_o  = 1'b0;    
                ResultSrc_o = 2'bxx;
                MemRead_o   = 4'b0000;
                Jump_o      = 1'b0;
                Jalr_o      = 1'b0;
                Branch_o    = 1'b0;
                ALUsrc_o    = 1'b1;    //  RS1 + Offset
                ALUop_o     = 2'b00;
                ImmSrc_o    = 3'b010;  //  S-type
                ImmUI_o     = 1'bx;
                case(func3_i)
                    3'b000:  MemWrite_o = 4'b0001; // SB
                    3'b001:  MemWrite_o = 4'b0010; // SH
                    3'b010:  MemWrite_o = 4'b1000; // SW
                    default: MemWrite_o = 4'b0000;  
                endcase
            end

            // 5. B-Type Branch (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            7'b110_0011: begin
                RegWrite_o  = 1'b0;
                ResultSrc_o = 2'bxx;
                MemWrite_o  = 4'b0000;
                MemRead_o   = 4'b0000;
                Jump_o      = 1'b0;
                Jalr_o      = 1'b0;
                Branch_o    = 1'b1;    //  Branch
                ALUsrc_o    = 1'b0;    // compare RS1 và RS2
                ALUop_o     = 2'b01;   // check Branch
                ImmSrc_o    = 3'b011;  // Immediate B-type
                ImmUI_o     = 1'bx;
            end

            // J-Type (JAL)
            7'b110_1111: begin
                RegWrite_o  = 1'b1;
                ResultSrc_o = 2'b10;   // rd=pc+4
                MemWrite_o  = 4'b0000;
                MemRead_o   = 4'b0000;
                Jump_o      = 1'b1;    
                Jalr_o      = 1'b0;
                Branch_o    = 1'b0;
                ALUsrc_o    = 1'bx;
                ALUop_o     = 2'bxx;
                ImmSrc_o    = 3'b101;  // Immediate J-type
                ImmUI_o     = 1'bx;
            end

            //  I-Type Jump (JALR)
            7'b110_0111: begin
                RegWrite_o  = 1'b1;
                ResultSrc_o = 2'b10;   // rd=pc+4
                MemWrite_o  = 4'b0000;
                MemRead_o   = 4'b0000;
                Jump_o      = 1'b1;
                Jalr_o      = 1'b1;    //  RS1 + Immediate
                Branch_o    = 1'b0;
                ALUsrc_o    = 1'bx;
                ALUop_o     = 2'bxx;
                ImmSrc_o    = 3'b001;  // Immediate I-type
                ImmUI_o     = 1'bx;
            end

            // 8. U-Type (LUI - Nap 20 bit cao)
            7'b011_0111: begin
                RegWrite_o  = 1'b1;
                ResultSrc_o = 2'b11;   // U-type
                MemWrite_o  = 4'b0000;
                MemRead_o   = 4'b0000;
                Jump_o      = 1'b0;
                Jalr_o      = 1'b0;
                Branch_o    = 1'b0;
                ALUsrc_o    = 1'bx;
                ALUop_o     = 2'bxx;
                ImmSrc_o    = 3'b100;  // Immediate U-type
                ImmUI_o     = 1'b1;    // 1: Ch?n tr?c ti?p imm_extd
            end

            // 9.  U-Type (AUIPC - C?ng 20 bit cao vào PC)
            7'b001_0111: begin
                RegWrite_o  = 1'b1;
                ResultSrc_o = 2'b11;   // Ch?n ???ng d? li?u U-type
                MemWrite_o  = 4'b0000;
                MemRead_o   = 4'b0000;
                Jump_o      = 1'b0;
                Jalr_o      = 1'b0;
                Branch_o    = 1'b0;
                ALUsrc_o    = 1'bx;
                ALUop_o     = 2'bxx;
                ImmSrc_o    = 3'b100;  // Immediate u U-type
                ImmUI_o     = 1'b0;    //  PC + imm_extd
            end

            default: begin
                RegWrite_o  = 1'b0;
                ResultSrc_o = 2'b0;
                MemWrite_o  = 4'b0;
                MemRead_o   = 4'b0;
                Jump_o      = 1'b0;
                Jalr_o      = 1'b0;
                Branch_o    = 1'b0;
                ALUsrc_o    = 1'b0;
                ALUop_o     = 2'b0;
                ImmSrc_o    = 3'b0;
                ImmUI_o     = 1'b0;
            end
        endcase
    end
endmodule
