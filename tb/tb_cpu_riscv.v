`timescale 1ns / 1ps

module tb_Pipeline_CPU();

    reg CLK;
    reg nRST;

    // G?i thi?t k? Pipeline CPU
    Pipeline_CPU dut (
        .CLK  (CLK),
        .nRST (nRST)
    );

    // M?ng l?u k?t qu? k? v?ng
    reg [31:0] expected_regs [0:31];
    reg [7:0]  expected_dmem [0:4095];

    integer i;
    integer reg_errors, mem_errors;
    integer cycle_cnt;

    // T?o xung nh?p 10ns
    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK;
    end

    // =========================================================================
    // KH?I THEO DÕI VÀ IN TR?NG THÁI PIPELINE T?NG CHU K?
    // =========================================================================
    
    // Bi?n l?u chu?i tên l?nh (t?i ?a 8 ký t? = 64 bit)
    reg [63:0] if_instr_name;
    reg [63:0] id_instr_name;

    // Task d?ch mã máy sang tên l?nh
    task decode_instruction;
        input  [31:0] inst;
        output reg [63:0] name;
        reg [6:0] opcode;
        reg [2:0] func3;
        reg [6:0] func7;
        begin
            if (inst == 32'h00000000 || inst === 32'hxxxxxxxx) begin
                name = "NOP";
            end else begin
                opcode = inst[6:0];
                func3  = inst[14:12];
                func7  = inst[31:25];
                case (opcode)
                    7'b0110111: name = "LUI";
                    7'b0010111: name = "AUIPC";
                    7'b1101111: name = "JAL";
                    7'b1100111: name = "JALR";
                    7'b1100011: begin
                        case (func3)
                            3'b000: name = "BEQ";
                            3'b001: name = "BNE";
                            3'b100: name = "BLT";
                            3'b101: name = "BGE";
                            3'b110: name = "BLTU";
                            3'b111: name = "BGEU";
                            default: name = "UNK";
                        endcase
                    end
                    7'b0000011: begin
                        case (func3)
                            3'b000: name = "LB";
                            3'b001: name = "LH";
                            3'b010: name = "LW";
                            3'b100: name = "LBU";
                            3'b101: name = "LHU";
                            default: name = "UNK";
                        endcase
                    end
                    7'b0100011: begin
                        case (func3)
                            3'b000: name = "SB";
                            3'b001: name = "SH";
                            3'b010: name = "SW";
                            default: name = "UNK";
                        endcase
                    end
                    7'b0010011: begin
                        case (func3)
                            3'b000: name = "ADDI";
                            3'b010: name = "SLTI";
                            3'b011: name = "SLTIU";
                            3'b100: name = "XORI";
                            3'b110: name = "ORI";
                            3'b111: name = "ANDI";
                            3'b001: name = "SLLI";
                            3'b101: name = func7[5] ? "SRAI" : "SRLI";
                            default: name = "UNK";
                        endcase
                    end
                    7'b0110011: begin
                        case (func3)
                            3'b000: name = func7[5] ? "SUB" : "ADD";
                            3'b001: name = "SLL";
                            3'b010: name = "SLT";
                            3'b011: name = "SLTU";
                            3'b100: name = "XOR";
                            3'b101: name = func7[5] ? "SRA" : "SRL";
                            3'b110: name = "OR";
                            3'b111: name = "AND";
                            default: name = "UNK";
                        endcase
                    end
                    default: name = "UNK";
                endcase
            end
        end
    endtask

    always @(negedge CLK) begin
        if (nRST) begin
            // Gi?i mã l?nh ?ang ??ng ? t?ng IF và ID
            decode_instruction(dut.Instr_F, if_instr_name);
            decode_instruction(dut.Instr_D, id_instr_name);

            $display("\n==========================================================================");
            $display("[Chu ky %0d] (Time: %0t ns)", cycle_cnt, $time);
            
            // In k?t qu? kèm theo tên l?nh (%0s)
            $display("  [IF ] PC = 0x%08h | Instr = 0x%08h (%0s) | Stall_F = %b", 
                     dut.PC_F, dut.Instr_F, if_instr_name, dut.Stall_F);
            
            $display("  [ID ] PC = 0x%08h | Instr = 0x%08h (%0s) | Stall_D = %b | Flush_D = %b", 
                     dut.PC_D, dut.Instr_D, id_instr_name, dut.Stall_D, dut.Flush_D);
            
            $display("  [EX ] PC = 0x%08h | ALUOut = 0x%08h | FwdA = %b | FwdB = %b | Flush_E = %b", 
                     dut.PC_E, dut.ALUResult_E, dut.ForwardA_E, dut.ForwardB_E, dut.Flush_E);
            
            if (dut.PCSrc_E) begin
                $display("        >>> [BRANCH/JUMP TAKEN] Nhay den dia chi: 0x%08h", dut.Target_E);
            end

            $display("  [MEM] MemWrite = %b | MemRead = %b | Addr = 0x%08h | WData = 0x%08h", 
                     dut.MemWrite_M, dut.MemRead_M, dut.ALUResult_M, dut.WriteData_M);
            
            if (dut.RegWrite_W && dut.RD_addr_W != 5'b0) begin
                $display("  [WB ] Ghi vao x%0d <= 0x%08h", dut.RD_addr_W, dut.Result_W);
            end else begin
                $display("  [WB ] Khong ghi RegFile");
            end
            
            cycle_cnt = cycle_cnt + 1;
        end
    end

    // =========================================================================
    // LU?NG KI?M TH? CHÍNH
    // =========================================================================
    initial begin
        // ??c d? li?u t? file sinh ra b?i Python
        $readmemh("D:/kairo/32multi/project_1/expected_regs.hex", expected_regs);
        $readmemh("D:/kairo/32multi/project_1/expected_dmem.hex", expected_dmem);

        nRST = 1'b0;
        reg_errors = 0;
        mem_errors = 0;
        cycle_cnt  = 1;

        // Reset h? th?ng
        @(posedge CLK);
        @(negedge CLK);
        nRST = 1'b1;

        $display("===================================================================");
        $display(" BAT DAU MO PHONG PIPELINE CPU (IN CHI TIET TUNG CHU KY)");
        $display("===================================================================");

        // Ch? 100 chu k? ?? toàn b? l?nh trôi qua h?t 5 t?ng
        repeat(100) @(posedge CLK);
        
        // D?ng l?i ? s??n xu?ng ?? ki?m tra tr?ng thái cu?i cùng
        @(negedge CLK);

        // -----------------------------------------------------------------
        // SO SÁNH 32 THANH GHI
        // -----------------------------------------------------------------
        $display("\n================ KIEM TRA FINAL REGISTERS ==================");
        for (i = 0; i < 32; i = i + 1) begin
            if (dut.u_RegFile.x[i] !== expected_regs[i]) begin
                $display("[FAIL] x%02d = 0x%08h | Expected = 0x%08h", i, dut.u_RegFile.x[i], expected_regs[i]);
                reg_errors = reg_errors + 1;
            end
        end
        if (reg_errors == 0) $display(" -> [PASS] Toan bo 32 thanh ghi khop 100%%!");

        // -----------------------------------------------------------------
        // SO SÁNH DATA MEMORY (4096 bytes)
        // -----------------------------------------------------------------
        $display("\n================ KIEM TRA FINAL DATA MEMORY ==================");
        for (i = 0; i < 4096; i = i + 1) begin
            if (dut.u_Data_Mem.DATA_MEM[i] !== expected_dmem[i]) begin
                $display("[FAIL] MEM[0x%03h] = 0x%02h | Expected = 0x%02h", i, dut.u_Data_Mem.DATA_MEM[i], expected_dmem[i]);
                mem_errors = mem_errors + 1;
            end
        end
        if (mem_errors == 0) $display(" -> [PASS] Toan bo Data Memory khop 100%%!");

        // -----------------------------------------------------------------
        // T?NG K?T
        // -----------------------------------------------------------------
        $display("\n===================================================================");
        if (reg_errors == 0 && mem_errors == 0)
            $display(" >>> KET QUA: [ PIPELINE CPU PASSED 100%% ] <<<");
        else
            $display(" >>> KET QUA: [ FAILED - CO LOI XAY RA ] <<<");
        $display("===================================================================\n");

        $finish;
    end

endmodule
