module instruction_memory (
    input  [31:0] pc,
    output [31:0] instruction
);

    // Create a memory array: 256 lines deep, 32 bits wide per line
    reg [31:0] rom [0:255];

    initial begin
        // Loads your compiled assembly code into the ROM at power-up
       $readmemh("/home/mathew/Pixel_Processor_SystolicArray/program.hex", rom); 
// (Update this path to wherever the file actually lives)
    end

    // Combinational Read: Grab the instruction at the current PC address.
    // We use pc[7:0] because our memory is only 256 words deep (which requires 8 bits to address).
    assign instruction = rom[pc[7:0]]; 

endmodule
