module coprocessor_fsm_4x4 (
    input             clk,
    input             rst,
    input             matrix_en,
    input      [1:0]  matrix_op,       
    input             fifo_ready,      
    output reg        cpu_stall,       
    output reg        fsm_read_en,     
    output reg        fsm_write_en,
    output reg        fifo_clear       // NEW: Wipes the Input FIFO
);

    localparam IDLE    = 2'd0;
    localparam COMPUTE = 2'd1;
    localparam DONE    = 2'd2;         // NEW: Escape state
    
    reg [1:0] current_state, next_state;
    reg [3:0] timer; 

    always @(posedge clk) begin
        if (rst) begin
            current_state <= IDLE;
            timer         <= 4'd0;
        end else begin
            current_state <= next_state;
            if (current_state == COMPUTE) timer <= timer + 1'b1;
            else timer <= 4'd0;
        end
    end

    always @(*) begin
        next_state = current_state; 
        case (current_state)
            IDLE: begin
                if (matrix_en && matrix_op == 2'b10 && fifo_ready) next_state = COMPUTE;
            end
            COMPUTE: begin
                if (timer == 4'd10) next_state = DONE;
            end
            DONE: begin
                next_state = IDLE; // Forces a 1-cycle delay
            end
        endcase
    end

    always @(*) begin
        cpu_stall    = 1'b0;
        fsm_read_en  = 1'b0;
        fsm_write_en = 1'b0;
        fifo_clear   = 1'b0;

        case (current_state)
            IDLE: begin
                if (matrix_en && matrix_op == 2'b10) cpu_stall = 1'b1; 
            end
            COMPUTE: begin
                cpu_stall = 1'b1; 
                if (timer < 4'd4) fsm_read_en = 1'b1;
                if (timer == 4'd10) fsm_write_en = 1'b1;
            end
            DONE: begin
                cpu_stall  = 1'b0; // RELEASE THE CPU BRAKES!
                fifo_clear = 1'b1; // WIPE THE FIFOS!
            end
        endcase
    end
endmodule