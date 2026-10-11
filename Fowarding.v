`timescale 1ns / 1ps

module Forwarding_Unit (
    input  wire [4:0] RS1_addr_E,  // Thanh ghi ngu?n 1 ? t?ng Execute
    input  wire [4:0] RS2_addr_E,  // Thanh ghi ngu?n 2 ? t?ng Execute
    
    input  wire [4:0] RD_addr_M,   // Thanh ghi ?ích ?ang ? t?ng Memory
    input  wire       RegWrite_M,  // Tín hi?u cho phép ghi c?a l?nh ? t?ng Memory
    input  wire [4:0] RD_addr_W,   // Thanh ghi ?ích ?ang ? t?ng Write-Back
    input  wire       RegWrite_W,  // Tín hi?u cho phép ghi c?a l?nh ? t?ng Write-Back
    
    output reg  [1:0] ForwardA,    // ?i?u khi?n Mux Forward cho ngõ vào ALU 1 (RS1)
    output reg  [1:0] ForwardB     // ?i?u khi?n Mux Forward cho ngõ vào ALU 2 (RS2)
);
    // 00: Không Forwarding, l?y giá tr? ??c t? RegFile (RS_data_E)
    // 01: Forward t? t?ng MEM/WB (D? li?u Write-Back: Result_W)
    // 10: Forward t? t?ng EX/MEM (K?t qu? tính xong c?a l?nh tr??c: ALUResult_M)

    always @(*) begin
        ForwardA = 2'b00;
        ForwardB = 2'b00;
        // Ngõ vào ALU A (RS1)
        if (RegWrite_M && (RD_addr_M != 5'b0) && (RD_addr_M == RS1_addr_E)) begin
            ForwardA = 2'b10;
        end
        // Ngõ vào ALU B (RS2)
        else if (RegWrite_W && (RD_addr_W != 5'b0) && (RD_addr_W == RS1_addr_E)) begin
            ForwardA = 2'b01;
        end
        // Ngõ vào ALU B (RS2)
        if (RegWrite_M && (RD_addr_M != 5'b0) && (RD_addr_M == RS2_addr_E)) begin
            ForwardB = 2'b10;
        end
        else if (RegWrite_W && (RD_addr_W != 5'b0) && (RD_addr_W == RS2_addr_E)) begin
            ForwardB = 2'b01;
        end
    end
endmodule
