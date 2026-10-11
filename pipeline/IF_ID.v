`timescale 1ns / 1ps

module IF_ID (
    input  wire        CLK,
    input  wire        nRST,
    input  wire        Stall_i,    //  Load-Use Hazard)
    input  wire        Flush_i,    // nop when branch or jump
    input  wire [31:0] PC_i,
    input  wire [31:0] PCPlus4_i,
    input  wire [31:0] Instr_i,
    output reg  [31:0] PC_o,
    output reg  [31:0] PCPlus4_o,
    output reg  [31:0] Instr_o
);
    always @(posedge CLK or negedge nRST) begin
        if (~nRST) begin
            PC_o      <= 32'b0;
            PCPlus4_o <= 32'b0;
            Instr_o   <= 32'b0;
        end
        else if (Flush_i) begin
            PC_o      <= 32'b0;
            PCPlus4_o <= 32'b0;
            Instr_o   <= 32'b0;
        end
        else if (~Stall_i) begin
            PC_o      <= PC_i;
            PCPlus4_o <= PCPlus4_i;
            Instr_o   <= Instr_i;
        end
    end
endmodule
