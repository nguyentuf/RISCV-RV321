`timescale 1ns / 1ps

module MEM_WB (
    input  wire        CLK,
    input  wire        nRST,
    // Control
    input  wire        RegWrite_i,
    input  wire [ 1:0] ResultSrc_i,
    // Datapath
    input  wire [31:0] ALUResult_i,
    input  wire [31:0] ReadData_i,   // data_o from datamem
    input  wire [31:0] PCPlus4_i,
    input  wire [31:0] UIData_i,
    input  wire [ 4:0] RD_addr_i,
    // Outputs sang t?ng WB
    output reg         RegWrite_o,
    output reg  [ 1:0] ResultSrc_o,
    output reg  [31:0] ALUResult_o,
    output reg  [31:0] ReadData_o,
    output reg  [31:0] PCPlus4_o,
    output reg  [31:0] UIData_o,
    output reg  [ 4:0] RD_addr_o
);
    always @(posedge CLK or negedge nRST) begin
        if (~nRST) begin
            RegWrite_o  <= 1'b0;
            ResultSrc_o <= 2'b00;
            ALUResult_o <= 32'b0;
            ReadData_o  <= 32'b0;
            PCPlus4_o   <= 32'b0;
            UIData_o    <= 32'b0;
            RD_addr_o   <= 5'b0;
        end
        else begin
            RegWrite_o  <= RegWrite_i;
            ResultSrc_o <= ResultSrc_i;
            ALUResult_o <= ALUResult_i;
            ReadData_o  <= ReadData_i;
            PCPlus4_o   <= PCPlus4_i;
            UIData_o    <= UIData_i;
            RD_addr_o   <= RD_addr_i;
        end
    end
endmodule
