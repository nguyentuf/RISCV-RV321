module PC_pipe (
    input  wire        CLK,
    input  wire        nRST,
    input  wire        Stall_i,   // 1: Gi? nguyên PC
    input  wire [31:0] PC_Next_i,
    output reg  [31:0] PC_o
);
    always @(posedge CLK or negedge nRST) begin
        if (~nRST) begin
            PC_o <= 32'h00000000;
        end 
        else if (Stall_i) begin
            PC_o <= PC_o;         
        end 
        else begin
            PC_o <= PC_Next_i;    
        end
    end
endmodule
