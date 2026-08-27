module cpu_core (
    input         clk,
    input         rst,
    
    // Connection to Instruction Memory (ROM)
    output [31:0] pc_out,
    input  [31:0] instruction_in,
    
    // ==========================================
    // NEW: Connection to Data Memory (RAM)
    // ==========================================
    output [31:0] mem_addr,         // Calculated by the ALU
    output [31:0] mem_write_data,   // Comes from rs2
    input  [31:0] mem_read_data,    // Data returning from RAM
    output        mem_read,         // From Control Unit
    output        mem_write,        // From Control Unit
    
    // Connection to Coprocessor Wrapper
    input         cpu_stall,
    output        matrix_en,
    output [1:0]  matrix_op,
    output        write_weight_en,
    output        write_pixel_en,
    output        cpu_read_en,
    output [15:0] copro_data_out, // Data going TO the FIFOs
    input  [31:0] copro_data_in   // Data coming FROM the Output FIFO
);

    // ==========================================
    // INTERNAL WIRES
    // ==========================================
    
    // Decode Wires
    wire [5:0]  opcode_wire;
    wire [4:0]  rd_wire, rs1_wire, rs2_wire;
    wire [10:0] imm_wire;
    
    // Control Wires
    wire reg_write_wire, alu_src_wire, branch_wire;
    wire mem_to_reg_wire; // NEW: Tells the RegFile to save RAM data instead of ALU data
    
    // Data Wires
    wire [31:0] rdata1_wire, rdata2_wire, alu_result_wire;
    wire branch_taken_wire;

    // Decoding Matrix Control Signals from Opcode
    // 0x20 = LWM, 0x21 = LDM, 0x22 = MMUL, 0x23 = SMR
    assign write_weight_en = (opcode_wire == 6'h20);
    assign write_pixel_en  = (opcode_wire == 6'h21);
    assign cpu_read_en     = (opcode_wire == 6'h23);
    
    // Map data out to coprocessor (using lower 16 bits of Read Data 1)
    assign copro_data_out = rdata1_wire[15:0];

    // ==========================================
    // NEW: DATA RAM ROUTING
    // ==========================================
    // The ALU computes the target memory address (Base Register + Immediate Offset)
    assign mem_addr = alu_result_wire; 
    
    // If STORE is called, the data to write is pulled from rs2
    assign mem_write_data = rdata2_wire; 

    // ==========================================
    // 1. FETCH STAGE
    // ==========================================
    fetch_stage my_fetch (
        .clk          (clk),
        .rst          (rst),
        .cpu_stall    (cpu_stall),         
        .branch_taken (branch_taken_wire), 
        .immediate    (imm_wire),          
        .pc           (pc_out)
    );

    // ==========================================
    // 2. INSTRUCTION DECODER
    // ==========================================
    instruction_decode my_decode (
        .instruction (instruction_in),
        .opcode      (opcode_wire),
        .reg_dest    (rd_wire),
        .reg_src1    (rs1_wire),
        .reg_src2    (rs2_wire),
        .immediate   (imm_wire)
    );

    // ==========================================
    // 3. CONTROL UNIT (Updated with Memory Flags)
    // ==========================================
    control_unit my_control (
        .opcode     (opcode_wire),
        .reg_write  (reg_write_wire),
        .alu_src    (alu_src_wire),
        .branch     (branch_wire),
        .mem_read   (mem_read),        // Outputs to top-level RAM
        .mem_write  (mem_write),       // Outputs to top-level RAM
        .mem_to_reg (mem_to_reg_wire), // Internal wire to the 3-Way Mux
        .matrix_en  (matrix_en),
        .matrix_op  (matrix_op)
    );

    // ==========================================
    // 4. REGISTER FILE (Upgraded to 3-Way Mux)
    // ==========================================
    wire [31:0] writeback_mux;
    
    // The hardware decision tree for what gets saved onto the CPU's desk
    assign writeback_mux = 
        (cpu_read_en)     ? copro_data_in :  // 1. SMR: Save matrix result
        (mem_to_reg_wire) ? mem_read_data :  // 2. LOAD: Save data loaded from RAM
                            alu_result_wire; // 3. Default: Save ALU math result

    register_file my_regfile (
        .clk        (clk),
        .rst        (rst),
        .reg_write  (reg_write_wire),
        .read_addr1 (rs1_wire),
        .read_addr2 (rs2_wire),
        .write_addr (rd_wire),
        .write_data (writeback_mux),
        .read_data1 (rdata1_wire),
        .read_data2 (rdata2_wire)
    );

    // ==========================================
    // 5. EXECUTE STAGE (ALU)
    // ==========================================
    execute_stage my_execute (
        .read_data1   (rdata1_wire),
        .read_data2   (rdata2_wire),
        .immediate    (imm_wire),
        .alu_src      (alu_src_wire),
        .branch       (branch_wire),
        .alu_result   (alu_result_wire),
        .branch_taken (branch_taken_wire) 
    );

endmodule