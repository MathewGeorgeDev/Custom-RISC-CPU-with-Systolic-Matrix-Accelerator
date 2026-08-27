module fetch_stage (
    input             clk,
    input             rst,
    
    // Control signals from other stages
    input             cpu_stall,      // From the Coprocessor FSM (The Brakes)
    input             branch_taken,   // From the Execute Stage (The Hijack)
    input      [10:0] immediate,      // From the Decode Stage (The Jump Distance)
    
    // Output to the Instruction Memory
    output reg [31:0] pc
);

    // Sign-extend the 11-bit immediate so we can add it to the 32-bit PC
    // This allows jumping backward (negative offset) or forward (positive offset)
    wire [31:0] sign_ext_imm;
    assign sign_ext_imm = {{21{immediate[10]}}, immediate};

    always @(posedge clk) begin
        // 1. HARD RESET
        if (rst) begin
            pc <= 32'd0; // Send the CPU back to the very first line of code
        end 
        
        // 2. THE COPROCESSOR FREEZE
        else if (cpu_stall) begin
            pc <= pc;    // Maintain current value. Do not increment!
        end 
        
        // 3. THE BRANCH (BNE)
        else if (branch_taken) begin
            // Jump forward or backward by the immediate offset
            pc <= pc + sign_ext_imm; 
        end 
        
        // 4. NORMAL EXECUTION
        else begin
            pc <= pc + 1'b1; // Grab the next line of code
        end
    end

endmodule
