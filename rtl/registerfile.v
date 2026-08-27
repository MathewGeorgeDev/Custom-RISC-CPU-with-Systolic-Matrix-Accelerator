module register_file (
    input         clk,
    input         rst,
    
    // Control Signal
    input         reg_write,     // 1 = Write allowed, 0 = Write protected
    
    // Addresses from the Instruction Decoder
    input  [4:0]  read_addr1,    // rs1
    input  [4:0]  read_addr2,    // rs2
    input  [4:0]  write_addr,    // rd (comes back from EX/Writeback stage)
    
    // Data flowing in and out
    input  [31:0] write_data,    // The answer coming back from the ALU/Memory
    output [31:0] read_data1,    // The data going to ALU input A
    output [31:0] read_data2     // The data going to ALU input B
);

    // The actual silicon memory banks: 32 registers, 32 bits wide
    reg [31:0] registers [0:31];
    integer i;

    // ==========================================
    // 1. READ LOGIC (Instant / Combinational)
    // ==========================================
    // If the address is 0, force the output to 0. Otherwise, output the register data.
    assign read_data1 = (read_addr1 == 5'd0) ? 32'd0 : registers[read_addr1];
    assign read_data2 = (read_addr2 == 5'd0) ? 32'd0 : registers[read_addr2];


    // ==========================================
    // 2. WRITE LOGIC (Clocked / Sequential)
    // ==========================================
    always @(posedge clk) begin
        if (rst) begin
            // On reset, wipe all registers clean
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end
        else if (reg_write) begin
            // Only write if the Control Unit allows it, AND never overwrite Register 0
            if (write_addr != 5'd0) begin
                registers[write_addr] <= write_data;
            end
        end
    end

endmodule
