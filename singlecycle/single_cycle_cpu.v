module Single_Cycle_CPU (
    input wire CLK,
    input wire nRST
);
    wire [31:0] pc_curr, pc_next, pc_plus4, pc_target, jalr_target, br_jump_target;
    wire [31:0] instr;
    wire        RegWrite, Jump, Jalr, Branch, ALUSrc, ImmUI;
    wire [ 1:0] ResultSrc, ALUOp;
    wire [ 2:0] ImmSrc;
    wire [ 3:0] MemWrite, MemRead, ALUCtrl;
    wire [31:0] rs1_data, rs2_data, imm_extd;
    wire [31:0] alu_in2, alu_result;
    wire        alu_br, br_taken, pc_src;
    wire [31:0] mem_read_data, ui_data, wb_result;

    // 1. KH?I FETCH (L?y l?nh)
    PC u_PC (
        .CLK       (CLK),
        .nRST      (nRST),
        .PC_Next_i (pc_next),
        .PC_o      (pc_curr)
    );

    Add2_32b u_Add_PC4 (
        .data1_i   (pc_curr),
        .data2_i   (32'd4),
        .data_o    (pc_plus4)
    );

    Instr_Mem u_Instr_Mem (
        .pc_i      (pc_curr),
        .instr_o   (instr)
    );

    // 2. KH?I DECODE & CONTROL (Gi?i mã l?nh)
    Ctrl_Unit u_Ctrl_Unit (
        .opcode_i    (instr[6:0]),
        .func3_i     (instr[14:12]),
        .RegWrite_o  (RegWrite),
        .ResultSrc_o (ResultSrc),
        .MemWrite_o  (MemWrite),
        .MemRead_o   (MemRead),
        .Jump_o      (Jump),
        .Jalr_o      (Jalr),
        .Branch_o    (Branch),
        .ALUsrc_o    (ALUSrc),
        .ALUop_o     (ALUOp),
        .ImmSrc_o    (ImmSrc),
        .ImmUI_o     (ImmUI)
    );

    RegFile u_RegFile (
        .CLK         (CLK),
        .RegWrite_i  (RegWrite),
        .RS1_addr_i  (instr[19:15]),
        .RS2_addr_i  (instr[24:20]),
        .RD_addr_i   (instr[11:7]),
        .WriteData_i (wb_result),
        .RS1_data_o  (rs1_data),
        .RS2_data_o  (rs2_data)
    );

    Extend u_Extend (
        .Instr       (instr[31:7]),
        .src         (ImmSrc),
        .imm_extd    (imm_extd)
    );

    ALUctrl u_ALUctrl (
        .ALUop_i     (ALUOp),
        .func3_i     (instr[14:12]),
        .func7_i     (instr[30]),
        .opcode_i    (instr[5]),
        .ALUctrl_o   (ALUCtrl)
    );

    // =========================================================================
    // 3. KH?I EXECUTE (Th?c thi & Tính ??a ch? nh?y)
    //(ALUSrc = 0: rs2_data, 1: imm_extd)
    assign alu_in2 = ALUSrc ? imm_extd : rs2_data;

    ALU u_ALU (
        .ALU_Ctrl    (ALUCtrl),
        .data1_i     (rs1_data),
        .data2_i     (alu_in2),
        .result      (alu_result),
        .ALU_Br      (alu_br)
    );

    // Tính PC + Immediate (cho Branch, JAL, AUIPC)
    Add2_32b u_Add_Target (
        .data1_i     (pc_curr),
        .data2_i     (imm_extd),
        .data_o      (pc_target)
    );

    // Tính RS1 + Immediate (cho JALR)
    Add2_32b u_Add_Jalr (
        .data1_i     (rs1_data),
        .data2_i     (imm_extd),
        .data_o      (jalr_target)
    );

    // (Jalr = 0: pc_target, 1: jalr_target)
    assign br_jump_target = Jalr ? jalr_target : pc_target;

    assign br_taken = Branch & alu_br;
    assign pc_src   = br_taken | Jump;

    // (pc_src = 0: pc_plus4, 1: br_jump_target)
    assign pc_next  = pc_src ? br_jump_target : pc_plus4;

    // 4. KH?I MEMORY (Truy xu?t RAM)
    Data_Mem u_Data_Mem (
        .CLK         (CLK),
        .rEN         (MemRead),
        .wEN         (MemWrite),
        .addr_i      (alu_result),
        .data_i      (rs2_data),
        .data_o      (mem_read_data)
    );

    // 5. KH?I WRITE BACK (Ghi ng??c v? RegFile)
    // Mux 2-sang-1: Ch?n d? li?u U-Type (ImmUI = 0: pc_target [AUIPC], 1: imm_extd [LUI])
    assign ui_data = ImmUI ? imm_extd : pc_target;

    // Mux 4-sang-1: Ch?n k?t qu? cu?i cùng ghi v? RegFile
    assign wb_result = (ResultSrc == 2'b00) ? alu_result    :
                       (ResultSrc == 2'b01) ? mem_read_data :
                       (ResultSrc == 2'b10) ? pc_plus4      :
                                              ui_data;

endmodule
