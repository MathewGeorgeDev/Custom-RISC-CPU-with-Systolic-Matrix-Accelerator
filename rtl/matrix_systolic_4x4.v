module matrix_systolic_4x4
                          (input clk,
                           input rst,
                           input [15:0] a_in_0, a_in_1, a_in_2, a_in_3,
                           input [15:0] b_in_0, b_in_1, b_in_2, b_in_3,
                           output [511:0] c_out_flat);

reg [15:0] a_r1_d1, b_c1_d1;
reg [15:0] a_r2_d1, b_c2_d1, a_r2_d2, b_c2_d2;
reg [15:0] a_r3_d1, a_r3_d2, a_r3_d3, b_c3_d1, b_c3_d2, b_c3_d3;

    always @(posedge clk) begin
    if(rst) begin 
            a_r1_d1 <= 0; b_c1_d1 <= 0;
            a_r2_d1 <= 0; a_r2_d2 <= 0; b_c2_d1 <= 0; b_c2_d2 <= 0;
            a_r3_d1 <= 0; a_r3_d2 <= 0; a_r3_d3 <= 0; b_c3_d1 <= 0; b_c3_d2 <= 0; b_c3_d3 <= 0;
            end else begin
           
           a_r1_d1 <= a_in_1;
           a_r2_d1 <= a_in_2; a_r2_d2 <= a_r2_d1;
           a_r3_d1 <= a_in_3; a_r3_d2 <= a_r3_d1; a_r3_d3 <= a_r3_d2;
           
           b_c1_d1 <= b_in_1;
           b_c2_d1 <= b_in_2; b_c2_d2 <= b_c2_d1;
           b_c3_d1 <= b_in_3; b_c3_d2 <= b_c3_d1; b_c3_d3 <= b_c3_d2;
           end
           end
           
           wire [15:0] a_wire [0:3][0:4];
           wire [15:0] b_wire [0:4][0:3];
           wire [31:0] c_wire [0:3][0:3];
           
           assign a_wire[0][0] = a_in_0;
           assign a_wire[1][0] = a_r1_d1;
           assign a_wire[2][0] = a_r2_d2;
           assign a_wire[3][0] = a_r3_d3;

           assign b_wire[0][0] = b_in_0;
           assign b_wire[0][1] = b_c1_d1;
           assign b_wire[0][2] = b_c2_d2;
           assign b_wire[0][3] = b_c3_d3;
           
           genvar r, c;
    generate
        for (r = 0; r < 4; r = r + 1) begin : row
            for (c = 0; c < 4; c = c + 1) begin : col
                matrix_pe pe_inst (
                    .clk   (clk),
                    .rst   (rst),
                    .a_in  (a_wire[r][c]),
                    .b_in  (b_wire[r][c]),
                    .a_out (a_wire[r][c+1]), // Propagates right
                    .b_out (b_wire[r+1][c]), // Propagates down
                    .c_out (c_wire[r][c])    // Stationary partial sum
                );
            end
        end
    endgenerate

    // Flatten the 2D array output into a 1D bus for compatibility
    assign c_out_flat = {
        c_wire[3][3], c_wire[3][2], c_wire[3][1], c_wire[3][0],
        c_wire[2][3], c_wire[2][2], c_wire[2][1], c_wire[2][0],
        c_wire[1][3], c_wire[1][2], c_wire[1][1], c_wire[1][0],
        c_wire[0][3], c_wire[0][2], c_wire[0][1], c_wire[0][0]
    };

endmodule