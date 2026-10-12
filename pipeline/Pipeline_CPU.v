`timescale 1ns / 1ps

module Pipeline_CPU (
    input wire CLK,
    input wire nRST
);
    
    // Wires T?ng Fetch (IF)
    wire [31:0] PC_F, PCPlus4_F, Instr_F, PC_Next_F;
    
    // Wires T?ng Decode (ID)
    wire [31:0] Instr_D, PC_D, PCPlus4_D;
    wire        RegWrite_D, Jump_D, Jalr_D, Branch_D, ALUSrc_D, ImmUI_D;
    wire [ 1:0] ResultSrc_D, ALUOp_D;
    wire [ 2:0] ImmSrc_D;
    wire [ 3:0] MemWrite_D, MemRead_D, ALUCtrl_D;
    wire [31:0] RS1_data_D, RS2_data_D, ImmExtd_D;
    
    // Wires T?ng Execute (EX)
    wire        RegWrite_E, Jump_E, Jalr_E, Branch_E, ALUSrc_E, ImmUI_E;
    wire [ 1:0] ResultSrc_E;
    wire [ 3:0] MemWrite_E, MemRead_E, ALUCtrl_E;
    wire [31:0] PC_E, PCPlus4_E, RS1_data_E, RS2_data_E, ImmExtd_E;
    wire [ 4:0] RS1_addr_E, RS2_addr_E, RD_addr_E;
    wire [31:0] ALUIn1_E, ALUIn2_E, Forwarded_RS2_E, ALUResult_E;
    wire [31:0] PCTarget_E, JalrTarget_E, UIData_E, Target_E;
    wire        ALU_Br_E, PCSrc_E;
    wire [ 1:0] ForwardA_E, ForwardB_E;

    // Wires T?ng Memory (MEM)
    wire        RegWrite_M;
    wire [ 1:0] ResultSrc_M;
    wire [ 3:0] MemWrite_M, MemRead_M;
    wire [31:0] ALUResult_M, WriteData_M, PCPlus4_M, UIData_M, ReadData_M;
    wire [31:0] ForwardData_M; // Dây ch?n d? li?u Forward t? t?ng MEM
    wire [ 4:0] RD_addr_M;

    // Wires T?ng Write-Back (WB)
    wire        RegWrite_W;
    wire [ 1:0] ResultSrc_W;
    wire [31:0] ALUResult_W, ReadData_W, PCPlus4_W, UIData_W;
    wire [ 4:0] RD_addr_W;
    wire [31:0] Result_W;
    wire Stall_F, Stall_D, Flush_D, Flush_E;

    // =========================================================================
    // T?NG 1: INSTRUCTION FETCH (IF)
    // =========================================================================
    
    // Mux ch?n PC k? ti?p: L?y t? k?t qu? nh?y ? t?ng EX (PCSrc_E), n?u không thì PC+4
    assign PC_Next_F = PCSrc_E ? Target_E : PCPlus4_F;

    PC_pipe u_PC (
        .CLK       (CLK),
        .nRST      (nRST),
        .Stall_i   (Stall_F),       // D?ng khi Load-Use
        .PC_Next_i (PC_Next_F),
        .PC_o      (PC_F)
    );

    Add2_32b u_Add_PC4 (
        .data1_i   (PC_F),
        .data2_i   (32'd4),
        .data_o    (PCPlus4_F)
    );

    Instr_Mem u_Instr_Mem (
        .pc_i      (PC_F),
        .instr_o   (Instr_F)
    );

    // -------------------------------------------------------------------------
    // THANH GHI IF/ID
    // -------------------------------------------------------------------------
    IF_ID u_IF_ID (
        .CLK       (CLK),
        .nRST      (nRST),
        .Stall_i   (Stall_D),       // D?ng khi Load-Use
        .Flush_i   (Flush_D),       // Xóa khi Branch/Jump
        .PC_i      (PC_F),
        .PCPlus4_i (PCPlus4_F),
        .Instr_i   (Instr_F),
        .PC_o      (PC_D),
        .PCPlus4_o (PCPlus4_D),
        .Instr_o   (Instr_D)
    );

    // =========================================================================
    // T?NG 2: INSTRUCTION DECODE (ID)
    // =========================================================================
    Ctrl_Unit u_Ctrl_Unit (
        .opcode_i    (Instr_D[6:0]),
        .func3_i     (Instr_D[14:12]),
        .RegWrite_o  (RegWrite_D),
        .ResultSrc_o (ResultSrc_D),
        .MemWrite_o  (MemWrite_D),
        .MemRead_o   (MemRead_D),
        .Jump_o      (Jump_D),
        .Jalr_o      (Jalr_D),
        .Branch_o    (Branch_D),
        .ALUsrc_o    (ALUSrc_D),
        .ALUop_o     (ALUOp_D),
        .ImmSrc_o    (ImmSrc_D),
        .ImmUI_o     (ImmUI_D)
    );

    ALUctrl u_ALUctrl (
        .ALUop_i     (ALUOp_D),
        .func3_i     (Instr_D[14:12]),
        .func7_i     (Instr_D[30]),
        .opcode_i    (Instr_D[5]),
        .ALUctrl_o   (ALUCtrl_D)
    );

    RegFile_pipe u_RegFile (
        .CLK         (CLK),
        .RegWrite_i  (RegWrite_W),
        .RS1_addr_i  (Instr_D[19:15]),
        .RS2_addr_i  (Instr_D[24:20]),
        .RD_addr_i   (RD_addr_W),
        .WriteData_i (Result_W),
        .RS1_data_o  (RS1_data_D),
        .RS2_data_o  (RS2_data_D)
    );

    Extend u_Extend (
        .Instr       (Instr_D[31:7]),
        .src         (ImmSrc_D),
        .imm_extd    (ImmExtd_D)
    );

    // -------------------------------------------------------------------------
    // THANH GHI ID/EX
    // -------------------------------------------------------------------------
    ID_EX u_ID_EX (
        .CLK         (CLK),
        .nRST        (nRST),
        .Flush_i     (Flush_E),      // Xóa khi Load-Use ho?c Branch/Jump
        .RegWrite_i  (RegWrite_D),
        .ResultSrc_i (ResultSrc_D),
        .MemWrite_i  (MemWrite_D),
        .MemRead_i   (MemRead_D),
        .Jump_i      (Jump_D),
        .Jalr_i      (Jalr_D),
        .Branch_i    (Branch_D),
        .ALUSrc_i    (ALUSrc_D),
        .ImmUI_i     (ImmUI_D),
        .ALUCtrl_i   (ALUCtrl_D),
        .PC_i        (PC_D),
        .PCPlus4_i   (PCPlus4_D),
        .RS1_data_i  (RS1_data_D),
        .RS2_data_i  (RS2_data_D),
        .ImmExtd_i   (ImmExtd_D),
        .RS1_addr_i  (Instr_D[19:15]),
        .RS2_addr_i  (Instr_D[24:20]),
        .RD_addr_i   (Instr_D[11:7]),
        
        .RegWrite_o  (RegWrite_E),
        .ResultSrc_o (ResultSrc_E),
        .MemWrite_o  (MemWrite_E),
        .MemRead_o   (MemRead_E),
        .Jump_o      (Jump_E),
        .Jalr_o      (Jalr_E),
        .Branch_o    (Branch_E),
        .ALUSrc_o    (ALUSrc_E),
        .ImmUI_o     (ImmUI_E),
        .ALUCtrl_o   (ALUCtrl_E),
        .PC_o        (PC_E),
        .PCPlus4_o   (PCPlus4_E),
        .RS1_data_o  (RS1_data_E),
        .RS2_data_o  (RS2_data_E),
        .ImmExtd_o   (ImmExtd_E),
        .RS1_addr_o  (RS1_addr_E),
        .RS2_addr_o  (RS2_addr_E),
        .RD_addr_o   (RD_addr_E)
    );

    // =========================================================================
    // T?NG 3: EXECUTE (EX) VÀ FORWARDING
    // =========================================================================
    Forwarding_Unit u_Forwarding_Unit (
        .RS1_addr_E (RS1_addr_E),
        .RS2_addr_E (RS2_addr_E),
        .RD_addr_M  (RD_addr_M),
        .RegWrite_M (RegWrite_M),
        .RD_addr_W  (RD_addr_W),
        .RegWrite_W (RegWrite_W),
        .ForwardA   (ForwardA_E),
        .ForwardB   (ForwardB_E)
    );

    // Ch?n ngu?n d? li?u chu?n t? t?ng MEM ?? Forward (h? tr? c? ALU, JAL/JALR, LUI/AUIPC)
    assign ForwardData_M = (ResultSrc_M == 2'b10) ? PCPlus4_M   :
                           (ResultSrc_M == 2'b11) ? UIData_M    :
                                                    ALUResult_M;

    // Mux Forwarding cho RS1
    assign ALUIn1_E = (ForwardA_E == 2'b10) ? ForwardData_M :
                      (ForwardA_E == 2'b01) ? Result_W      :
                                              RS1_data_E;

    // Mux Forwarding cho RS2
    assign Forwarded_RS2_E = (ForwardB_E == 2'b10) ? ForwardData_M :
                             (ForwardB_E == 2'b01) ? Result_W      :
                                                     RS2_data_E;

    // Ch?n gi?a Immediate ho?c RS2 ?ã Forward
    assign ALUIn2_E = ALUSrc_E ? ImmExtd_E : Forwarded_RS2_E;

    ALU u_ALU (
        .ALU_Ctrl    (ALUCtrl_E),
        .data1_i     (ALUIn1_E),
        .data2_i     (ALUIn2_E),
        .result      (ALUResult_E),
        .ALU_Br      (ALU_Br_E)
    );

    // Tính ??a ch? Branch / JAL / AUIPC (PC + Imm)
    Add2_32b u_Add_Target (
        .data1_i     (PC_E),
        .data2_i     (ImmExtd_E),
        .data_o      (PCTarget_E)
    );

    // Tính ??a ch? JALR (Dùng RS1 ?ã Forward + Imm)
    Add2_32b u_Add_Jalr (
        .data1_i     (ALUIn1_E),
        .data2_i     (ImmExtd_E),
        .data_o      (JalrTarget_E)
    );

    assign UIData_E = ImmUI_E ? ImmExtd_E : PCTarget_E;

    assign PCSrc_E  = (Branch_E & ALU_Br_E) | Jump_E;
    assign Target_E = Jalr_E ? {JalrTarget_E[31:1], 1'b0} : PCTarget_E; // Xóa bit 0 khi JALR

    // -------------------------------------------------------------------------
    // THANH GHI EX/MEM
    // -------------------------------------------------------------------------
    EX_MEM u_EX_MEM (
        .CLK         (CLK),
        .nRST        (nRST),
        .RegWrite_i  (RegWrite_E),
        .ResultSrc_i (ResultSrc_E),
        .MemWrite_i  (MemWrite_E),
        .MemRead_i   (MemRead_E),
        .ALUResult_i (ALUResult_E),
        .WriteData_i (Forwarded_RS2_E), // RS2 ?ã ???c Forward
        .PCPlus4_i   (PCPlus4_E),
        .UIData_i    (UIData_E),
        .RD_addr_i   (RD_addr_E),
        
        .RegWrite_o  (RegWrite_M),
        .ResultSrc_o (ResultSrc_M),
        .MemWrite_o  (MemWrite_M),
        .MemRead_o   (MemRead_M),
        .ALUResult_o (ALUResult_M),
        .WriteData_o (WriteData_M),
        .PCPlus4_o   (PCPlus4_M),
        .UIData_o    (UIData_M),
        .RD_addr_o   (RD_addr_M)
    );

    // =========================================================================
    // T?NG 4: MEMORY (MEM)
    // =========================================================================
    Data_Mem u_Data_Mem (
        .CLK         (CLK),
        .rEN         (MemRead_M),
        .wEN         (MemWrite_M),
        .addr_i      (ALUResult_M),
        .data_i      (WriteData_M),
        .data_o      (ReadData_M)
    );

    // -------------------------------------------------------------------------
    // THANH GHI MEM/WB
    // -------------------------------------------------------------------------
    MEM_WB u_MEM_WB (
        .CLK         (CLK),
        .nRST        (nRST),
        .RegWrite_i  (RegWrite_M),
        .ResultSrc_i (ResultSrc_M),
        .ALUResult_i (ALUResult_M),
        .ReadData_i  (ReadData_M),
        .PCPlus4_i   (PCPlus4_M),
        .UIData_i    (UIData_M),
        .RD_addr_i   (RD_addr_M),

        .RegWrite_o  (RegWrite_W),
        .ResultSrc_o (ResultSrc_W),
        .ALUResult_o (ALUResult_W),
        .ReadData_o  (ReadData_W),
        .PCPlus4_o   (PCPlus4_W),
        .UIData_o    (UIData_W),
        .RD_addr_o   (RD_addr_W)
    );

    // =========================================================================
    // T?NG 5: WRITE-BACK (WB)
    // =========================================================================
    assign Result_W = (ResultSrc_W == 2'b00) ? ALUResult_W :
                      (ResultSrc_W == 2'b01) ? ReadData_W  :
                      (ResultSrc_W == 2'b10) ? PCPlus4_W   :
                                               UIData_W;

    // =========================================================================
    // T?NG 6: HAZARD UNIT (Dò xung ??t Load-Use và Control)
    // =========================================================================
    Hazard_Unit u_Hazard_Unit (
        .RS1_addr_D (Instr_D[19:15]),
        .RS2_addr_D (Instr_D[24:20]),
        .RD_addr_E  (RD_addr_E),
        .MemRead_E  (MemRead_E),
        .PCSrc_E    (PCSrc_E),        // Khi b?ng 1 -> Xóa l?nh ?ang n?p nh?m ? IF và ID
        
        .Stall_F    (Stall_F),
        .Stall_D    (Stall_D),
        .Flush_D    (Flush_D),
        .Flush_E    (Flush_E)
    );

endmodule
