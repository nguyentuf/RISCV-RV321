module PC (
    input  wire        CLK,
    input  wire        nRST,
    input  wire        Stall_i,
    input  wire [31:0] PC_Next_i,
    output reg  [31:0] PC_o
);
    always @(posedge CLK or negedge nRST) begin
        if (~nRST)         PC_o <= 32'h00000000;
        else  PC_o <= PC_Next_i;
    end
endmodule