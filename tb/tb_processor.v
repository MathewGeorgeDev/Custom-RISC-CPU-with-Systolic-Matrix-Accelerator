module tb_processor();

    // ==========================================
    // 1. SIGNAL DECLARATIONS
    // ==========================================
    reg clk;
    reg rst;

    // ==========================================
    // 2. INSTANTIATE THE MOTHERBOARD (SoC)
    // ==========================================
    pixel_processor_top uut (
        .clk(clk),
        .rst(rst)
    );

    // ==========================================
    // 3. CLOCK GENERATION (100 MHz)
    // ==========================================
    // The clock flips every 5 nanoseconds, creating a 10ns period.
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ==========================================
    // 4. SYSTEM RESET & TIMEOUT
    // ==========================================
    initial begin
        // Print to the Vivado Tcl Console
        $display("========================================");
        $display("   STARTING SoC BEHAVIORAL SIMULATION   ");
        $display("========================================");
        
        // 1. Assert Hard Reset
        rst = 1;
        
        // Hold reset for a few clock cycles to flush all pipeline registers, 
        // FIFO pointers, and the Coprocessor FSM down to zero.
        #20; 
        
        // 2. Release Reset (Boot the CPU)
        rst = 0;
        $display("System Boot: CPU Fetching from ROM...");

        // 3. Let the software run
        // We give the CPU enough simulated time (in nanoseconds) to load 
        // the matrices, run the 10-cycle array computation, and store the answers.
        #4000000;
        
        // 4. End the simulation
        $display("========================================");
        $display("          SIMULATION COMPLETE           ");
        $display("========================================");
        $writememh("/home/mathew/Pixel_Processor_SystolicArray/output_data.hex", uut.my_ram.ram, 0, 1023);
        $finish;
    end

    // ==========================================
    // 5. HARDWARE MONITORING (Optional but highly recommended)
    // ==========================================
    // This block automatically prints a log to your console anytime the CPU Stall wire flips,
    // so you can see exactly when the Coprocessor hijacks the system.
    initial begin
        $monitor("Time: %0t ns | PC: %h | FSM Stall: %b", 
                 $time, uut.my_cpu.pc_out, uut.my_cpu.cpu_stall);
    end

endmodule
