`timescale 1ns / 1ps

module Hazard_Unit (
    input  wire [4:0] RS1_addr_D,  // Thanh ghi ngu?n 1 ? t?ng Decode
    input  wire [4:0] RS2_addr_D,  // Thanh ghi ngu?n 2 ? t?ng Decode
    input  wire [4:0] RD_addr_E,   // Thanh ghi rd Execute
    input  wire [3:0] MemRead_E,   //khác 0000 là Load
    input  wire       PCSrc_E,     // C? nh?y thành công t? t?ng Execute (Branch Taken ho?c Jump)

    // Các tín hi?u ?i?u khi?n xu?t ra
    output wire       Stall_F,     // D?ng c?p nh?t PC (t?ng Fetch)
    output wire       Stall_D,     // D?ng thanh ghi IF/ID
    output wire       Flush_D,     // Xóa l?nh ? thanh ghi IF/ID (thành NOP)
    output wire       Flush_E      // Xóa l?nh ? thanh ghi ID/EX (thành NOP)
);

    // 1. Dò Load-Use Hazard
    // N?u l?nh ? EX là LOAD và thanh ghi ?ích c?a nó trùng v?i thanh ghi ngu?n c?a l?nh ? ID
    wire lw_stall;
    assign lw_stall = (MemRead_E != 4'b0000) && (RD_addr_E != 5'b0) && 
                      ((RD_addr_E == RS1_addr_D) || (RD_addr_E == RS2_addr_D));

    // load word stall -> maintain cpu
    assign Stall_F = lw_stall;
    assign Stall_D = lw_stall;

    // 3. Quy?t ??nh tín hi?u Flush (Xóa Pipeline)
    // - Xóa t?ng ID n?u x?y ra nh?y nhánh (PCSrc_E = 1) ?? v?t b? l?nh n?p nh?m ? IF.
    assign Flush_D = PCSrc_E;
    
    // - Xóa t?ng EX n?u x?y ra nh?y nhánh (PCSrc_E = 1) ?? v?t b? l?nh n?p nh?m ? ID, 
    // HO?C n?u x?y ra Load-Use stall (?? chèn bong bóng NOP vào t?ng EX ch? 1 chu k?).
    assign Flush_E = lw_stall | PCSrc_E;

endmodule