module Data_Mem (
    input  wire        CLK,
    input  wire [ 3:0] rEN,      // 1000: LW, 0010: LH, 1010: LHU, 0001: LB, 1001: LBU[cite: 6]
    input  wire [ 3:0] wEN,      // 1000: SW, 0010: SH, 0001: SB
    input  wire [31:0] addr_i,
    input  wire [31:0] data_i,
    output reg  [31:0] data_o
);
    reg [7:0] DATA_MEM [0:4095]; 
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            DATA_MEM[i] = 8'h00;
        end
    end
    always @(*) begin
        case (rEN)
            4'b1000: data_o = {DATA_MEM[addr_i+3], DATA_MEM[addr_i+2], DATA_MEM[addr_i+1], DATA_MEM[addr_i]};
            4'b0010: data_o = {{16{DATA_MEM[addr_i+1][7]}}, DATA_MEM[addr_i+1], DATA_MEM[addr_i]}; // LH
            4'b1010: data_o = {16'b0, DATA_MEM[addr_i+1], DATA_MEM[addr_i]}; // LHU[cite: 6]
            4'b0001: data_o = {{24{DATA_MEM[addr_i][7]}}, DATA_MEM[addr_i]}; // LB[cite: 6]
            4'b1001: data_o = {24'b0, DATA_MEM[addr_i]}; // LBU[cite: 6]
            default: data_o = 32'b0;
        endcase
    end
    
    // Write (Store)
    always @(posedge CLK) begin // store 1,2,4 byte
        if (wEN[3]) begin //store word
            DATA_MEM[addr_i+3] <= data_i[31:24]; 
            DATA_MEM[addr_i+2] <= data_i[23:16]; 
            DATA_MEM[addr_i+1] <= data_i[15:8];  
            DATA_MEM[addr_i]   <= data_i[7:0];   
        end
        else if (wEN[1]) begin //store halfword
            DATA_MEM[addr_i+1] <= data_i[15:8];  
            DATA_MEM[addr_i]   <= data_i[7:0];   
        end //store byte
        else if (wEN[0]) begin // SB[cite: 6]
            DATA_MEM[addr_i]   <= data_i[7:0];   //[cite: 6]
        end
    end
endmodule