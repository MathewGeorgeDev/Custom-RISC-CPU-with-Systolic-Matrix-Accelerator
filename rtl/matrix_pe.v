module matrix_pe (
    input clk,
    input rst,
    
    input [15:0] a_in,
    input [15:0] b_in,
    
    output reg [15:0] a_out,
    output reg [15:0] b_out,
    output reg [31:0] c_out
);

always @(posedge clk) begin
        if(rst) begin
            b_out <= 16'b0;
            a_out <= 16'b0;
            c_out <= 32'b0;
    end
    else begin
    
    a_out <= a_in;
    b_out <= b_in;
    c_out <= c_out + (a_in * b_in);
    end
    end
endmodule    
