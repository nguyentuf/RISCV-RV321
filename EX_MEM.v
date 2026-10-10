`timescale 1ns / 1ps

module EX_MEM (
    input  wire        CLK,
    input  wire        nRST,
    // Control
    input  wire        RegWrite_i,
    input  wire [ 1:0] ResultSrc_i,
    input  wire [ 3:0] MemWrite_i,
    input  wire [ 3:0] MemRead_i,
    // Datapath
    input  wire [31:0] ALUResult_i,
    input  wire [31:0] WriteData_i,  // RS2_data 
    input  wire [31:0] PCPlus4_i,
    input  wire [31:0] UIData_i,     // K?t qu? LUI / AUIPC
    input  wire [ 4:0] RD_addr_i,
    // Outputs sang t?ng MEM
    output reg         RegWrite_o,
    output reg  [ 1:0] ResultSrc_o,
    output reg  [ 3:0] MemWrite_o,
    output reg  [ 3:0] MemRead_o,
    output reg  [31:0] ALUResult_o,
    output reg  [31:0] WriteData_o,
    output reg  [31:0] PCPlus4_o,
    output reg  [31:0] UIData_o,
    output reg  [ 4:0] RD_addr_o
);
    always @(posedge CLK or negedge nRST) begin
        if (~nRST) begin
            RegWrite_o  <= 1'b0;
            ResultSrc_o <= 2'b00;
            MemWrite_o  <= 4'b0000;
            MemRead_o   <= 4'b0000;
            ALUResult_o <= 32'b0;
            WriteData_o <= 32'b0;
            PCPlus4_o   <= 32'b0;
            UIData_o    <= 32'b0;
            RD_addr_o   <= 5'b0;
        end
        else begin
            RegWrite_o  <= RegWrite_i;
            ResultSrc_o <= ResultSrc_i;
            MemWrite_o  <= MemWrite_i;
            MemRead_o   <= MemRead_i;
            ALUResult_o <= ALUResult_i;
            WriteData_o <= WriteData_i;
            PCPlus4_o   <= PCPlus4_i;
            UIData_o    <= UIData_i;
            RD_addr_o   <= RD_addr_i;
        end
    end
endmodule
