`timescale 1ns / 1ps

module ID_EX (
    input  wire        CLK,
    input  wire        nRST,
    input  wire        Flush_i,     
    // Tín hi?u Control
    input  wire        RegWrite_i,
    input  wire [ 1:0] ResultSrc_i,
    input  wire [ 3:0] MemWrite_i,
    input  wire [ 3:0] MemRead_i,
    input  wire        Jump_i,
    input  wire        Jalr_i,
    input  wire        Branch_i,
    input  wire        ALUSrc_i,
    input  wire        ImmUI_i,
    input  wire [ 3:0] ALUCtrl_i,
    // Tín hi?u Datapath
    input  wire [31:0] PC_i,
    input  wire [31:0] PCPlus4_i,
    input  wire [31:0] RS1_data_i,
    input  wire [31:0] RS2_data_i,
    input  wire [31:0] ImmExtd_i,
    input  wire [ 4:0] RS1_addr_i,
    input  wire [ 4:0] RS2_addr_i,
    input  wire [ 4:0] RD_addr_i,
    // Outputs sang t?ng EX
    output reg         RegWrite_o,
    output reg  [ 1:0] ResultSrc_o,
    output reg  [ 3:0] MemWrite_o,
    output reg  [ 3:0] MemRead_o,
    output reg         Jump_o,
    output reg         Jalr_o,
    output reg         Branch_o,
    output reg         ALUSrc_o,
    output reg         ImmUI_o,
    output reg  [ 3:0] ALUCtrl_o,
    output reg  [31:0] PC_o,
    output reg  [31:0] PCPlus4_o,
    output reg  [31:0] RS1_data_o,
    output reg  [31:0] RS2_data_o,
    output reg  [31:0] ImmExtd_o,
    output reg  [ 4:0] RS1_addr_o,
    output reg  [ 4:0] RS2_addr_o,
    output reg  [ 4:0] RD_addr_o
);
    always @(posedge CLK or negedge nRST) begin
        if (~nRST || Flush_i) begin
            RegWrite_o  <= 1'b0;
            ResultSrc_o <= 2'b00;
            MemWrite_o  <= 4'b0000;
            MemRead_o   <= 4'b0000;
            Jump_o      <= 1'b0;
            Jalr_o      <= 1'b0;
            Branch_o    <= 1'b0;
            ALUSrc_o    <= 1'b0;
            ImmUI_o     <= 1'b0;
            ALUCtrl_o   <= 4'b0000;
            PC_o        <= 32'b0;
            PCPlus4_o   <= 32'b0;
            RS1_data_o  <= 32'b0;
            RS2_data_o  <= 32'b0;
            ImmExtd_o   <= 32'b0;
            RS1_addr_o  <= 5'b0;
            RS2_addr_o  <= 5'b0;
            RD_addr_o   <= 5'b0;
        end
        else begin
            RegWrite_o  <= RegWrite_i;
            ResultSrc_o <= ResultSrc_i;
            MemWrite_o  <= MemWrite_i;
            MemRead_o   <= MemRead_i;
            Jump_o      <= Jump_i;
            Jalr_o      <= Jalr_i;
            Branch_o    <= Branch_i;
            ALUSrc_o    <= ALUSrc_i;
            ImmUI_o     <= ImmUI_i;
            ALUCtrl_o   <= ALUCtrl_i;
            PC_o        <= PC_i;
            PCPlus4_o   <= PCPlus4_i;
            RS1_data_o  <= RS1_data_i;
            RS2_data_o  <= RS2_data_i;
            ImmExtd_o   <= ImmExtd_i;
            RS1_addr_o  <= RS1_addr_i;
            RS2_addr_o  <= RS2_addr_i;
            RD_addr_o   <= RD_addr_i;
        end
    end
endmodule
