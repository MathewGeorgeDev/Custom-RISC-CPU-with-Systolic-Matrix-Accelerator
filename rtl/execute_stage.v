module execute_stage (
    // Data flowing in from Decode / Register File
    input  [31:0] read_data1,   // Rs1
    input  [31:0] read_data2,   // Rs2
    input  [10:0] immediate,    // 11-bit hardcoded number
    
    // Control signals from Control Unit
    input         alu_src,      // 0 = use Rs2, 1 = use Immediate
    input         branch,       // 1 = this is a BNE instruction
    
    // Data flowing out
    output [31:0] alu_result,   // The math answer (or memory address)
    output        branch_taken  // 1 = Jump to a new line of code!
);

    // ==========================================
    // 1. SIGN EXTENSION
    // ==========================================
    // Replicate the 10th bit (the sign bit) 21 times, then attach the original 11 bits.
    wire [31:0] sign_ext_imm;
    assign sign_ext_imm = {{21{immediate[10]}}, immediate};

    // ==========================================
    // 2. THE ALU MULTIPLEXER
    // ==========================================
    // Hardware switch: If alu_src is 1, output the Immediate. Else, output Rs2.
    wire [31:0] alu_operand2;
    assign alu_operand2 = (alu_src) ? sign_ext_imm : read_data2;

    // ==========================================
    // 3. THE MAIN ALU (The Adder)
    // ==========================================
    // Handles ADD, ADDI, LW, and SW calculations.
    assign alu_result = read_data1 + alu_operand2;

    // ==========================================
    // 4. BRANCH LOGIC (BNE)
    // ==========================================
    // branch_taken becomes 1 ONLY IF the instruction is a branch AND the inputs don't match.
    assign branch_taken = branch & (read_data1 != read_data2);

endmodule
