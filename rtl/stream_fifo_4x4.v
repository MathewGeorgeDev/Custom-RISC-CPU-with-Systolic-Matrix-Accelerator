module stream_fifo_4x4 (
    input             clk,
    input             rst,
    
    // ----------------------------------------------------
    // CPU Interface (Writing sequentially)
    // ----------------------------------------------------
    input             write_weight_en, // LWM instruction
    input             write_pixel_en,  // LDM instruction
    input      [15:0] cpu_write_data,  // 16-bit word from CPU
    
    // ----------------------------------------------------
    // Systolic Array Interface (Reading in parallel blocks)
    // ----------------------------------------------------
    input             fsm_read_en,     // High during the 4 stream cycles
    input             fifo_clear,
    
    output     [15:0] a_out_0, a_out_1, a_out_2, a_out_3, // A Column
    output     [15:0] b_out_0, b_out_1, b_out_2, b_out_3, // B Row
    
    // ----------------------------------------------------
    // Status Flags
    // ----------------------------------------------------
    output            fifo_ready       // Goes HIGH when 16 A's and 16 B's are loaded
);

    // Two 16-element arrays to hold the 4x4 matrices
    reg [15:0] matrix_a [0:15];
    reg [15:0] matrix_b [0:15];
    
    // Write counters (0 to 16)
    reg [4:0] a_count;
    reg [4:0] b_count;
    
    // Read cycle counter (0 to 3) for streaming into the array
    reg [2:0] read_ptr;

    // The FIFO is ready when both matrices are completely full
    assign fifo_ready = (a_count == 5'd16) && (b_count == 5'd16);

    // ==========================================
    // 1. SEQUENTIAL WRITE LOGIC (From CPU)
    // ==========================================
    always @(posedge clk) begin
        if (rst || fifo_clear) begin
            a_count  <= 5'd0;
            b_count  <= 5'd0;
            read_ptr <= 3'd0;
        end else begin
            
            // LWM: CPU writes Matrix A (Weights)
            if (write_weight_en && a_count < 5'd16) begin
                matrix_a[a_count] <= cpu_write_data;
                a_count           <= a_count + 1'b1;
            end
            
            // LDM: CPU writes Matrix B (Pixels)
            if (write_pixel_en && b_count < 5'd16) begin
                matrix_b[b_count] <= cpu_write_data;
                b_count           <= b_count + 1'b1;
            end
            
            // FSM reads data: Increment read pointer for 4 cycles
            if (fsm_read_en && read_ptr < 3'd4) begin
                read_ptr <= read_ptr + 1'b1;
            end
            
            // Once the FSM finishes reading (or if reset manually), we could reset counters.
            // For now, we rely on the Coprocessor FSM to reset this module between matrix operations
            // or we expect the CPU software to keep track of its writes.
        end
    end

    // ==========================================
    // 2. PARALLEL READ LOGIC (To Array)
    // ==========================================
    // We use combinational routing (wires) so the data hits the array 
    // on the exact same clock cycle the FSM requests it.
    
    // If FSM is reading, output Column [read_ptr] of Matrix A
    assign a_out_0 = (fsm_read_en) ? matrix_a[read_ptr]      : 16'd0;
    assign a_out_1 = (fsm_read_en) ? matrix_a[4 + read_ptr]  : 16'd0;
    assign a_out_2 = (fsm_read_en) ? matrix_a[8 + read_ptr]  : 16'd0;
    assign a_out_3 = (fsm_read_en) ? matrix_a[12 + read_ptr] : 16'd0;

    // If FSM is reading, output Row [read_ptr] of Matrix B
    // A row starts at read_ptr * 4. We use bit shifts (<< 2) instead of *4 for clean synthesis.
    wire [4:0] b_row_base = read_ptr * 4; 
    
    assign b_out_0 = (fsm_read_en) ? matrix_b[b_row_base]     : 16'd0;
    assign b_out_1 = (fsm_read_en) ? matrix_b[b_row_base + 1] : 16'd0;
    assign b_out_2 = (fsm_read_en) ? matrix_b[b_row_base + 2] : 16'd0;
    assign b_out_3 = (fsm_read_en) ? matrix_b[b_row_base + 3] : 16'd0;

endmodule