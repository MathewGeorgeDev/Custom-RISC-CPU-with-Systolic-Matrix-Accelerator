module coprocessor_top_4x4 (
    input         clk,
    input         rst,
    
    // CPU Control Interface
    input         matrix_en,
    input  [1:0]  matrix_op,
    input         write_weight_en,
    input         write_pixel_en,
    input         cpu_read_en,
    
    // CPU Data Interface
    input  [15:0] cpu_data_in,     // 16-bit word from CPU to FIFOs
    output [31:0] cpu_data_out,    // 32-bit result back to CPU
    
    // CPU Stall Signal
    output        cpu_stall
);

    // Internal routing wires
    wire         fifo_ready_wire;
    wire         fifo_clear_wire;
    wire         fsm_read_en_wire;
    wire         fsm_write_en_wire;
    wire [511:0] c_flat_wire;
    
    // Wires for the 4x4 A and B buses
    wire [15:0] a_0, a_1, a_2, a_3;
    wire [15:0] b_0, b_1, b_2, b_3;

    // 1. THE FSM
    coprocessor_fsm_4x4 my_fsm (
        .clk          (clk),
        .rst          (rst),
        .matrix_en    (matrix_en),
        .matrix_op    (matrix_op),
        .fifo_ready   (fifo_ready_wire),
        .cpu_stall    (cpu_stall),
        .fsm_read_en  (fsm_read_en_wire),
        .fifo_clear(fifo_clear_wire),
        .fsm_write_en (fsm_write_en_wire)
    );

    // 2. THE INPUT PACKING FIFO
    stream_fifo_4x4 my_input_fifo (
        .clk             (clk),
        .rst             (rst),
        .write_weight_en (write_weight_en),
        .write_pixel_en  (write_pixel_en),
        .cpu_write_data  (cpu_data_in),
        .fsm_read_en     (fsm_read_en_wire),
        .a_out_0(a_0), .a_out_1(a_1), .a_out_2(a_2), .a_out_3(a_3),
        .b_out_0(b_0), .b_out_1(b_1), .b_out_2(b_2), .b_out_3(b_3),
        .fifo_clear(fifo_clear_wire),
        .fifo_ready      (fifo_ready_wire)
    );

    // 3. THE 4x4 SYSTOLIC ARRAY
    matrix_systolic_4x4 my_array (
        .clk        (clk),
        .rst        (rst),
        .a_in_0(a_0), .a_in_1(a_1), .a_in_2(a_2), .a_in_3(a_3),
        .b_in_0(b_0), .b_in_1(b_1), .b_in_2(b_2), .b_in_3(b_3),
        .c_out_flat (c_flat_wire)
    );

    // 4. THE OUTPUT SERIALIZING FIFO
    output_fifo_4x4 my_output_fifo (
        .clk           (clk),
        .rst           (rst),
        .fsm_write_en  (fsm_write_en_wire),
        .c_out_flat    (c_flat_wire),
        .cpu_read_en   (cpu_read_en),
        .cpu_read_data (cpu_data_out),
        .fifo_empty    () // Can be left unconnected for now
    );

endmodule