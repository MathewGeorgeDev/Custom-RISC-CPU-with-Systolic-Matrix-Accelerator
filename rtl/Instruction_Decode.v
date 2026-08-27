module instruction_decode (
    input  [31:0] instruction,
    output [5:0]  opcode,
    output [4:0]  reg_dest,
    output [4:0]  reg_src1,
    output [4:0]  reg_src2,
    output [10:0] immediate
);

    // Hard-sliced wires. Zero logic gates required!
    assign opcode    = instruction[31:26];
    assign reg_dest  = instruction[25:21];
    assign reg_src1  = instruction[20:16];
    assign reg_src2  = instruction[15:11];
    assign immediate = instruction[10:0];

endmodule