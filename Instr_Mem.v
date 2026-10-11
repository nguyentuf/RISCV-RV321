module Instr_Mem (
    input  wire [31:0] pc_i,     
    output wire [31:0] instr_o   
);
    reg [7:0] ROM [0:1023];      // 2^10
    
    initial begin
        $readmemh("D:/kairo/32multi/project_1/imem.hex", ROM); 
    end

    // 4 byte to 1 Word 32-bit (Little Endian)
    assign instr_o = {ROM[pc_i+3], ROM[pc_i+2], ROM[pc_i+1], ROM[pc_i]};
endmodule