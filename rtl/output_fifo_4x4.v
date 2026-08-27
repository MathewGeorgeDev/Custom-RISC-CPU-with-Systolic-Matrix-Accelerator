module output_fifo_4x4 (
    input             clk,
    input             rst,
    
    // ----------------------------------------------------
    // Coprocessor FSM Interface (Parallel Write)
    // ----------------------------------------------------
    input             fsm_write_en,      // Goes HIGH for 1 cycle when math is done
    input     [511:0] c_out_flat,        // The massive bus from the Systolic Array
    
    // ----------------------------------------------------
    // CPU Interface (Sequential Read)
    // ----------------------------------------------------
    input             cpu_read_en,       // Triggered by SMR instruction
    output    [31:0]  cpu_read_data,     // Goes to CPU Writeback Mux
    
    // ----------------------------------------------------
    // Status Flags
    // ----------------------------------------------------
    output            fifo_empty         // HIGH when all 16 values are read
);

    // Internal memory to hold the 16 results
    reg [31:0] result_matrix [0:15];
    
    // Pointer to track which of the 16 values the CPU is reading (0 to 16)
    reg [4:0] read_ptr; 

    // The FIFO is empty when the CPU has read all 16 items, or before data is loaded
    assign fifo_empty = (read_ptr == 5'd16);

    // ==========================================
    // 1. COMBINATIONAL READ LOGIC (To CPU)
    // ==========================================
    // The data is instantly available on the wire so the CPU Execute stage can grab it
    assign cpu_read_data = (read_ptr < 5'd16) ? result_matrix[read_ptr[3:0]] : 32'd0;

    // ==========================================
    // 2. SYNCHRONOUS WRITE & POINTER LOGIC
    // ==========================================
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            read_ptr <= 5'd16; // Start empty (pointer at max)
            for (i = 0; i < 16; i = i + 1) begin
                result_matrix[i] <= 32'd0;
            end
        end else begin
            
            // A. FSM Parallel Write (The Flash Photograph)
            if (fsm_write_en) begin
                // Loop through the 512-bit bus and slice it into 32-bit chunks
                for (i = 0; i < 16; i = i + 1) begin
                    // Syntax [ (start_bit) +: (width) ] extracts perfectly sized slices
                    result_matrix[i] <= c_out_flat[(i*32) +: 32];
                end
                
                // Reset the read pointer to 0 so the CPU can start reading
                read_ptr <= 5'd0; 
            end
            
            // B. CPU Sequential Read (SMR)
            // We only increment the pointer; the combinational logic above handles the output
            else if (cpu_read_en && !fifo_empty) begin
                read_ptr <= read_ptr + 1'b1;
            end
            
        end
    end

endmodule