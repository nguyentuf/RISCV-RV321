`timescale 1ns / 1ps

module tb_Pipeline_Fibonacci();

    reg CLK;
    reg nRST;

    Pipeline_CPU dut (
        .CLK  (CLK),
        .nRST (nRST)
    );

    integer cycle_count;
    integer instr_count;
    real    ipc;

    // Clock 10ns
    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK;
    end

    initial begin
        nRST = 1'b0;
        cycle_count = 0;
        instr_count = 0;
        
        @(posedge CLK);
        @(negedge CLK);
        nRST = 1'b1;

        $display("==========================================================");
        $display(" BAT DAU BENCHMARK: FIBONACCI(10) TREN PIPELINE RV32I");
        $display("==========================================================");

        // Theo dõi quá trình ch?y
        while (1) begin
            @(posedge CLK);
            cycle_count = cycle_count + 1;
            
            // ??m s? l?nh th?c s? ch?t vào RegFile / Memory (b? qua bong bóng stall/flush)
            if (dut.RegWrite_W || dut.MemWrite_M) begin
                instr_count = instr_count + 1;
            end

            // ?i?u ki?n d?ng: Khi PC ? t?ng WB ch?t l?nh BEQ x0, x0, 0 (mã máy 0x00000063)
            // L?nh này n?m ? PC = 0x38
            if (dut.PC_F == 32'h00000038) begin
                // ??i thêm 4 chu k? ?? l?nh LW cu?i cùng ghi k?t qu? vào x7 ? t?ng WB
                repeat(4) @(posedge CLK);
                cycle_count = cycle_count + 4;
                
                $display("\n>>> KET QUA FIBONACCI(10) TAI THANH GHI x7: %0d", dut.u_RegFile.x[7]);
                
                if (dut.u_RegFile.x[7] == 55)
                    $display(" -> [PASS] Tinh toan chinh xac (Fib(10) = 55)!");
                else
                    $display(" -> [FAIL] Tinh toan SAI!");

                ipc = $itor(instr_count) / $itor(cycle_count);
                
                $display("\n================ BÁO CÁO HI?U N?NG =======================");
                $display(" - Tong so lenh thuc thi (Instruction Count): %0d", instr_count);
                $display(" - Tong so chu ky (Cycle Count)             : %0d cycles", cycle_count);
                $display(" - Hieu nang IPC (Instructions Per Cycle)   : %0.2f", ipc);
                $display(" - Ton that do Hazard (Stall/Flush)         : ~%0d cycles", cycle_count - instr_count - 4); // -4 là do n?p pipeline ban ??u
                $display("==========================================================");
                $finish;
            end
        end
    end

endmodule