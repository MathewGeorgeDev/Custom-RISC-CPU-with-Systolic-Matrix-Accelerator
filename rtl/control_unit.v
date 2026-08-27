module control_unit (
    input      [5:0] opcode,
    
    // Standard CPU Control Signals
    output reg       reg_write,  // 1 = Write to Register File
    output reg       alu_src,    // 0 = ALU uses Rs2, 1 = ALU uses Immediate
    output reg       mem_read,   // 1 = Read from Data RAM
    output reg       mem_write,  // 1 = Write to Data RAM
    output reg       mem_to_reg, // data move from data memory to register file
    output reg       branch,     // 1 = BNE (Branch if Not Equal)
    
    // Coprocessor (Systolic Array) Control Signals
    output reg       matrix_en,  // 1 = Wake up the Matrix FSM!
    output reg [1:0] matrix_op   // 00=LWM, 01=LDM, 10=MMUL, 11=SMR
);

    always @(*) begin
        // 1. DEFAULT SAFETY VALUES (Prevents Latches)
        reg_write = 1'b0;
        alu_src   = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        branch    = 1'b0;
        matrix_en = 1'b0;
        mem_to_reg = 1'b0;
        matrix_op = 2'b00;

        // 2. THE SWITCHBOARD
        case (opcode)
            // ------------------------------------
            // STANDARD CPU OPERATIONS
            // ------------------------------------
            6'b000001: begin // ADD
                reg_write = 1'b1;
                alu_src   = 1'b0; // Use Rs2
            end
            
            6'b000010: begin // ADDI (Add Immediate)
                reg_write = 1'b1;
                alu_src   = 1'b1; // Use Immediate
            end
            
            6'b000011: begin // LW (Load Word)
                reg_write = 1'b1;
                alu_src   = 1'b1; // Use Immediate for memory offset
                mem_read  = 1'b1;
                mem_to_reg = 1'b1;
            end
            
            6'b000100: begin // SW (Store Word)
                alu_src   = 1'b1; 
                mem_write = 1'b1;
            end
            
            6'b000101: begin // BNE (Branch Not Equal)
                branch    = 1'b1;
                // ALU does subtraction to compare Rs1 and Rs2, no write needed
            end
            
            
            // ------------------------------------
            // MATRIX COPROCESSOR OPERATIONS
            // ------------------------------------
            6'b100000: begin // LWM (Load Weight Matrix)
                matrix_en = 1'b1;
                matrix_op = 2'b00;
            end
            
            6'b100001: begin // LDM (Load Data Matrix)
                matrix_en = 1'b1;
                matrix_op = 2'b01;
            end
            
            6'b100010: begin // MMUL (Matrix Multiply)
                matrix_en = 1'b1;
                matrix_op = 2'b10;
            end
            
            6'b100011: begin // SMR (Store Matrix Result)
                matrix_en = 1'b1;
                matrix_op = 2'b11;
                reg_write = 1'b1; // Saving back to RAM
            end
            
            // 6'b111111: HALT (Defaults catch this and turn everything off)
        endcase
    end

endmodule