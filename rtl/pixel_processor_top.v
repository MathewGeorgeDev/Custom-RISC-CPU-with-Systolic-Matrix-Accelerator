module pixel_processor_top (
    input clk,
    input rst
);

    // ==========================================
    // INTERNAL MOTHERBOARD WIRES
    // ==========================================
    
    // CPU <-> Instruction ROM Wires
    wire [31:0] pc_wire;
    wire [31:0] instruction_wire;
    
    // CPU <-> Data RAM Wires
    wire [31:0] mem_addr_wire;
    wire [31:0] mem_write_data_wire;
    wire [31:0] mem_read_data_wire;
    wire        mem_read_wire;
    wire        mem_write_wire;
    
    // CPU <-> Coprocessor Control Wires
    wire        cpu_stall_wire;
    wire        matrix_en_wire;
    wire [1:0]  matrix_op_wire;
    wire        write_weight_en_wire;
    wire        write_pixel_en_wire;
    wire        cpu_read_en_wire;
    
    // CPU <-> Coprocessor Data Wires
    wire [15:0] copro_data_in_wire;  // 16-bit to array
    wire [31:0] copro_data_out_wire; // 32-bit from array

    // ==========================================
    // 1. INSTRUCTION MEMORY (ROM)
    // ==========================================
    instruction_memory my_rom (
        .pc          (pc_wire),
        .instruction (instruction_wire)
    );

    // ==========================================
    // 2. DATA MEMORY (RAM)
    // ==========================================
    data_memory my_ram (
        .clk         (clk),
        .mem_write   (mem_write_wire),
        .mem_read    (mem_read_wire),
        .address     (mem_addr_wire),
        .write_data  (mem_write_data_wire),
        .read_data   (mem_read_data_wire)
    );

    // ==========================================
    // 3. THE CPU CORE
    // ==========================================
    cpu_core my_cpu (
        .clk             (clk),
        .rst             (rst),
        
        // Instruction Interface
        .pc_out          (pc_wire),
        .instruction_in  (instruction_wire),
        
        // Data RAM Interface
        .mem_addr        (mem_addr_wire),
        .mem_write_data  (mem_write_data_wire),
        .mem_read_data   (mem_read_data_wire),
        .mem_read        (mem_read_wire),
        .mem_write       (mem_write_wire),
        
        // Coprocessor Interface
        .cpu_stall       (cpu_stall_wire),
        .matrix_en       (matrix_en_wire),
        .matrix_op       (matrix_op_wire),
        .write_weight_en (write_weight_en_wire),
        .write_pixel_en  (write_pixel_en_wire),
        .cpu_read_en     (cpu_read_en_wire),
        .copro_data_out  (copro_data_in_wire), 
        .copro_data_in   (copro_data_out_wire)
    );

    // ==========================================
    // 4. THE MATRIX COPROCESSOR
    // ==========================================
    coprocessor_top_4x4 my_coprocessor (
        .clk             (clk),
        .rst             (rst),
        .matrix_en       (matrix_en_wire),
        .matrix_op       (matrix_op_wire),
        .write_weight_en (write_weight_en_wire),
        .write_pixel_en  (write_pixel_en_wire),
        .cpu_read_en     (cpu_read_en_wire),
        .cpu_data_in     (copro_data_in_wire),
        .cpu_data_out    (copro_data_out_wire),
        .cpu_stall       (cpu_stall_wire)
    );

endmodule