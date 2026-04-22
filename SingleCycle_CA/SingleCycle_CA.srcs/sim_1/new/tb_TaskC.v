`timescale 1ns / 1ps
module tb_TaskC();

    reg clk;
    reg rst;
    reg [15:0] switches;
    
    wire [15:0] leds;
    wire [6:0] seg;
    wire [3:0] an;

    SingleCycle uut (
        .clk(clk),
        .rst(rst),
        .switches(switches),
        .leds(leds),
        .seg(seg),
        .an(an)
    );

    // Generate 100MHz clock
    always #5 clk = ~clk;

    initial begin
        // 1. Initialize
        clk = 0;
        rst = 1;
        switches = 16'd0;

        // 2. Release Reset
        #2000;
        rst = 0;

        // 3. Wait for processor to start polling
        #1000;

        // 4. Turn on Switch 6 (Priority encoded to value '6')
        // Binary: 0000_0000_0100_0000
        switches = 16'h0040; 
        
        // 5. Wait for the loop to calculate Fibonacci
        #5000; 

        // 6. Check results in console
        $display("Time: %0t | Switch Input (N) = 6 | LEDs Output = %d (Expected: 5)", $time, leds);
        
        #1000;
        $finish;
    end

endmodule