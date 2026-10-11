`timescale 1ns / 1ps

module tb_Single_Cycle_CPU();

    reg CLK;
    reg nRST;

    Single_Cycle_CPU dut (
        .CLK  (CLK),
        .nRST (nRST)
    );

    // 51 chu k? bao ph? toàn b? 37 l?nh RV32I
    localparam NUM_TEST_CYCLES = 51;

    reg [211:0] expected_trace [0:NUM_TEST_CYCLES-1];
    reg [31:0]  expected_regs  [0:31];
    reg [7:0]   expected_dmem  [0:4095];

    integer cycle_cnt;
    integer trace_errors, reg_errors, mem_errors;
    integer i;

    reg [31:0] exp_pc_curr, exp_instr, exp_pc_next, exp_wb_data, exp_mem_addr, exp_mem_wdata;
    reg [3:0]  exp_reg_write, exp_mem_read, exp_mem_write;
    reg [7:0]  exp_rd;
    reg        cycle_pass;

    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK;
    end

    // =========================================================================
    // TASK 1: IN TR?NG THÁI 32 THANH GHI T?I TH?I ?I?M B?T K?
    // =========================================================================
    task dump_registers(input integer current_cycle);
        integer r;
        begin
            $display("\n+------------------------------------------------------------------------------+");
            $display("| [REGISTER SNAPSHOT] Sau chu ky %02d (Time: %0t ns)                             |", current_cycle, $time);
            $display("+------------------------------------------------------------------------------+");
            for (r = 0; r < 32; r = r + 4) begin
                $display("| x%02d: 0x%08h | x%02d: 0x%08h | x%02d: 0x%08h | x%02d: 0x%08h |",
                    r,   dut.u_RegFile.x[r],
                    r+1, dut.u_RegFile.x[r+1],
                    r+2, dut.u_RegFile.x[r+2],
                    r+3, dut.u_RegFile.x[r+3]
                );
            end
            $display("+------------------------------------------------------------------------------+\n");
        end
    endtask

    // =========================================================================
    // TASK 2: IN TR?NG THÁI DATA MEMORY
    // =========================================================================
    task dump_memory(input [31:0] start_addr, input integer num_words);
        integer w, addr;
        reg [31:0] word_val;
        begin
            $display("+-------------------------------------------------------+");
            $display("| [DATA MEMORY SNAPSHOT] Tu dia chi 0x%04h (%0d words)   |", start_addr, num_words);
            $display("+-------------------------------------------------------+");
            for (w = 0; w < num_words; w = w + 1) begin
                addr = start_addr + w*4;
                word_val = {dut.u_Data_Mem.DATA_MEM[addr+3],
                            dut.u_Data_Mem.DATA_MEM[addr+2],
                            dut.u_Data_Mem.DATA_MEM[addr+1],
                            dut.u_Data_Mem.DATA_MEM[addr]};
                $display("| MEM[0x%04h..0x%04h] = 0x%08h                      |", addr+3, addr, word_val);
            end
            $display("+-------------------------------------------------------+\n");
        end
    endtask

    // =========================================================================
    // LU?NG KI?M TH? CHÍNH (FULL 37 INSTRUCTIONS)
    // =========================================================================
    initial begin
        $readmemh("D:/kairo/32multi/project_1/expected_trace.hex", expected_trace);
        $readmemh("D:/kairo/32multi/project_1/expected_regs.hex",  expected_regs);
        $readmemh("D:/kairo/32multi/project_1/expected_dmem.hex",  expected_dmem);

        nRST = 1'b0;
        trace_errors = 0;
        reg_errors   = 0;
        mem_errors   = 0;

        @(posedge CLK);
        @(negedge CLK);
        nRST = 1'b1;

        $display("================= BAT DAU TEST TOAN BO 37 LENH RV32I (51 CHU KY) =================");

        for (cycle_cnt = 0; cycle_cnt < NUM_TEST_CYCLES; cycle_cnt = cycle_cnt + 1) begin
            #4; // Ki?m tra t?i 1ns tr??c s??n lên CLK

            {exp_pc_curr, exp_instr, exp_pc_next, exp_reg_write, exp_rd,
             exp_wb_data, exp_mem_read, exp_mem_write, exp_mem_addr, exp_mem_wdata} = expected_trace[cycle_cnt];

            cycle_pass = 1'b1;

            // 1. Ki?m tra PC, Instr, PC_Next
            if (dut.pc_curr !== exp_pc_curr || dut.instr !== exp_instr || dut.pc_next !== exp_pc_next) begin
                cycle_pass = 1'b0;
                $display("[Cycle %02d][FAIL - PC/FLOW] PC: 0x%08h (Exp: 0x%08h) | PC_Next: 0x%08h (Exp: 0x%08h)",
                         cycle_cnt+1, dut.pc_curr, exp_pc_curr, dut.pc_next, exp_pc_next);
            end

            // 2. Ki?m tra LOAD (LB, LH, LW, LBU, LHU)
            if (exp_mem_read != 4'b0000 || dut.MemRead != 4'b0000) begin
                if (dut.MemRead !== exp_mem_read || dut.alu_result !== exp_mem_addr || dut.wb_result !== exp_wb_data) begin
                    cycle_pass = 1'b0;
                    $display("[Cycle %02d][FAIL - LOAD]    MemRead: %b (Exp: %b) | Addr: 0x%08h (Exp: 0x%08h) | Data: 0x%08h (Exp: 0x%08h)",
                             cycle_cnt+1, dut.MemRead, exp_mem_read, dut.alu_result, exp_mem_addr, dut.wb_result, exp_wb_data);
                end else begin
                    $display("[Cycle %02d][PASS - LOAD]    PC=0x%02h | Addr=0x%08h | MemRead=%b | Rd=x%02d <= 0x%08h",
                             cycle_cnt+1, dut.pc_curr, dut.alu_result, dut.MemRead, dut.instr[11:7], dut.wb_result);
                end
            end

            // 3. Ki?m tra STORE (SB, SH, SW)
            else if (exp_mem_write != 4'b0000 || dut.MemWrite != 4'b0000) begin
                if (dut.MemWrite !== exp_mem_write || dut.alu_result !== exp_mem_addr || dut.rs2_data !== exp_mem_wdata) begin
                    cycle_pass = 1'b0;
                    $display("[Cycle %02d][FAIL - STORE]   MemWrite: %b (Exp: %b) | Addr: 0x%08h (Exp: 0x%08h) | WData: 0x%08h (Exp: 0x%08h)",
                             cycle_cnt+1, dut.MemWrite, exp_mem_write, dut.alu_result, exp_mem_addr, dut.rs2_data, exp_mem_wdata);
                end else begin
                    $display("[Cycle %02d][PASS - STORE]   PC=0x%02h | Addr=0x%08h | MemWrite=%b | WData=0x%08h",
                             cycle_cnt+1, dut.pc_curr, dut.alu_result, dut.MemWrite, dut.rs2_data);
                end
            end

            // 4. Ki?m tra BRANCH (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            else if (dut.instr[6:0] == 7'b1100011) begin
                if (dut.pc_next === exp_pc_next) begin
                    $display("[Cycle %02d][PASS - BRANCH]  PC=0x%02h | func3=%b | Taken=%b | PC_Next=0x%08h",
                             cycle_cnt+1, dut.pc_curr, dut.instr[14:12], dut.br_taken, dut.pc_next);
                end
            end

            // 5. Ki?m tra JUMP (JAL, JALR)
            else if (dut.instr[6:0] == 7'b1101111 || dut.instr[6:0] == 7'b1100111) begin
                if (dut.RegWrite !== exp_reg_write[0] || (exp_rd != 0 && dut.wb_result !== exp_wb_data) || dut.pc_next !== exp_pc_next) begin
                    cycle_pass = 1'b0;
                    $display("[Cycle %02d][FAIL - JUMP]    WB(PC+4): 0x%08h (Exp: 0x%08h) | Target(PC_Next): 0x%08h (Exp: 0x%08h)",
                             cycle_cnt+1, dut.wb_result, exp_wb_data, dut.pc_next, exp_pc_next);
                end else begin
                    $display("[Cycle %02d][PASS - JUMP]    PC=0x%02h | Rd=x%02d <= 0x%08h (PC+4) | JumpTarget(PC_Next)=0x%08h",
                             cycle_cnt+1, dut.pc_curr, dut.instr[11:7], dut.wb_result, dut.pc_next);
                end
            end

            // 6. Ki?m tra R-Type, I-Type ALU, LUI, AUIPC
            else begin
                if (dut.RegWrite !== exp_reg_write[0] || (exp_reg_write[0] && exp_rd != 0 && dut.wb_result !== exp_wb_data)) begin
                    cycle_pass = 1'b0;
                    $display("[Cycle %02d][FAIL - ALU/WB]  RegWrite: %b (Exp: %b) | RD: x%02d | WB_Data: 0x%08h (Exp: 0x%08h)",
                             cycle_cnt+1, dut.RegWrite, exp_reg_write[0], dut.instr[11:7], dut.wb_result, exp_wb_data);
                end else begin
                    $display("[Cycle %02d][PASS - ALU/WB]  PC=0x%02h | Rd=x%02d <= 0x%08h | PC_Next=0x%08h",
                             cycle_cnt+1, dut.pc_curr, dut.instr[11:7], dut.wb_result, dut.pc_next);
                end
            end

            if (~cycle_pass) trace_errors = trace_errors + 1;

            @(posedge CLK);
            @(negedge CLK);

            // In Memory sau khi ch?y xong c?m l?nh Store/Load (Chu k? 33)
            if (cycle_cnt + 1 == 33) begin
                dump_memory(32'h0000_0010, 2); // Xem t? ??a ch? 16 (0x10)
            end
        end

        // =====================================================================
        // KI?M TRA CU?I CÙNG: 32 THANH GHI & 4096 BYTE DATA MEMORY
        // =====================================================================
        dump_registers(NUM_TEST_CYCLES);

        for (i = 0; i < 32; i = i + 1) begin
            if (dut.u_RegFile.x[i] !== expected_regs[i]) begin
                $display("[FINAL REG FAIL] x%02d = 0x%08h | Expected = 0x%08h", i, dut.u_RegFile.x[i], expected_regs[i]);
                reg_errors = reg_errors + 1;
            end
        end

        for (i = 0; i < 4096; i = i + 1) begin
            if (dut.u_Data_Mem.DATA_MEM[i] !== expected_dmem[i]) begin
                $display("[FINAL MEM FAIL] DATA_MEM[0x%03h] = 0x%02h | Expected = 0x%02h", i, dut.u_Data_Mem.DATA_MEM[i], expected_dmem[i]);
                mem_errors = mem_errors + 1;
            end
        end

        $display("\n=========================================================================================");
        $display(" TONG KET KIEM THU TOAN BO 37 LENH RV32I:");
        $display("  - Loi Trace tung chu ky (51 chu ky)       : %0d loi", trace_errors);
        $display("  - Loi 32 Thanh ghi cuoi cung (RegFile)    : %0d loi", reg_errors);
        $display("  - Loi 4096-Byte Bo nho du lieu (Data_Mem) : %0d loi", mem_errors);
        if (trace_errors == 0 && reg_errors == 0 && mem_errors == 0)
            $display(" >>> KET QUA: [ ALL 37 RV32I INSTRUCTIONS PASSED 100%% ] <<<");
        else
            $display(" >>> KET QUA: [ TEST FAILED ] <<<");
        $display("=========================================================================================\n");

        $finish;
    end

endmodule