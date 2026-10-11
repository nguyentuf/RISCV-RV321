module RegFile_pipe ( // Write first 
    input  wire        CLK,
    input  wire        RegWrite_i,
    input  wire [ 4:0] RS1_addr_i,
    input  wire [ 4:0] RS2_addr_i,
    input  wire [ 4:0] RD_addr_i,
    input  wire [31:0] WriteData_i,
    output wire [31:0] RS1_data_o,
    output wire [31:0] RS2_data_o
);
    reg [31:0] x [0:31];
    integer i;
    
    initial begin
        for(i = 0; i < 32; i = i + 1) x[i] = 32'b0;
    end

    always @(posedge CLK) begin
        if (RegWrite_i && (RD_addr_i != 5'b0)) begin
            x[RD_addr_i] <= WriteData_i;
        end
    end

    // ?u tiên l?y d? li?u WriteData_i n?u ?ang ??c thanh ghi s?p ???c ghi
    assign RS1_data_o = (RS1_addr_i == 5'b0) ? 32'b0 :
                        (RegWrite_i && (RS1_addr_i == RD_addr_i)) ? WriteData_i : x[RS1_addr_i];
    assign RS2_data_o = (RS2_addr_i == 5'b0) ? 32'b0 :
                        (RegWrite_i && (RS2_addr_i == RD_addr_i)) ? WriteData_i : x[RS2_addr_i];
endmodule
