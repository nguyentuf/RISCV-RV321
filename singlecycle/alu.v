module ALU (
    input wire  [ 3:0] ALU_Ctrl,
    input wire  [31:0] data1_i,
    input wire  [31:0] data2_i,
    output reg  [31:0] result,
    output reg         ALU_Br
);
    always @(*) begin
        case (ALU_Ctrl)
            4'h0 : result = data1_i + data2_i; // ADD
            4'h1 : result = data1_i - data2_i; // SUB
            4'h2 : result = data1_i ^ data2_i; // XOR
            4'h3 : result = data1_i | data2_i; // OR
            4'h4 : result = data1_i & data2_i; // AND
            4'h5 : result = data1_i << data2_i[4:0]; // SLL
            4'h6 : result = data1_i >> data2_i[4:0]; // SRL
            4'h7 : result = $signed(data1_i) >>> data2_i[4:0]; // SRA
            4'h8 : result = ($signed(data1_i) < $signed(data2_i)) ? 32'b1 : 32'b0; // SLT
            4'h9 : result = (data1_i < data2_i) ? 32'b1 : 32'b0; // SLTU
            default : result = 32'b0;
        endcase
    end

    always @(*) begin
        case (ALU_Ctrl)
            4'hA : ALU_Br =  (data1_i == data2_i); // BEQ
            4'hB : ALU_Br =  (data1_i != data2_i); // BNE
            4'hC : ALU_Br =  ($signed(data1_i) <  $signed(data2_i)); // BLT
            4'hD : ALU_Br = ~($signed(data1_i) <  $signed(data2_i)); // BGE
            4'hE : ALU_Br =  (data1_i <  data2_i); // BLTU
            4'hF : ALU_Br = ~(data1_i <  data2_i); // BGEU
            default: ALU_Br = 1'b0;
        endcase
    end
endmodule
