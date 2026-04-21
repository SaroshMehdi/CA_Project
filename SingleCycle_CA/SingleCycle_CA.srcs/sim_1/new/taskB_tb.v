`timescale 1ns / 1ps
module tb_TaskB();

    // Inputs
    reg clk;
    reg rst;
    reg [15:0] switches;

    // Outputs
    wire [15:0] leds;
    wire [6:0] seg;
    wire [3:0] an;

    // Instantiate the Top Level Processor
    SingleCycle uut (
        .clk(clk),
        .rst(rst),
        .switches(switches),
        .leds(leds),
        .seg(seg),
        .an(an)
    );

    // Generate 100MHz Clock (10ns period)
    always #5 clk = ~clk;

    // CPU runs at 10MHz (100ns period) due to clock divider in SingleCycle.
    // All timing comments below are in CPU cycles (1 CPU cycle = 100ns).

    initial begin
        // Initialize
        clk     = 0;
        rst     = 1;
        switches = 16'd0;

        // Hold reset for 200ns (20 CPU cycles - plenty of margin)
        #2000;
        rst = 0;

        // Wait for _start init (@00,@01 = 2 instr) + poll (@02) = 3 CPU cycles
        // Give 10 cycles of margin so x9/x18/x10 are all settled
        #1000;

        // =========================================================
        // TEST 1: SLLI  (Switch 1 -> encoded=1)
        // addi x5,x0,5  ->  slli x8,x5,1  ->  x8=10  ->  LED=0x000A
        // Path: @03->@04(fall)->@05->@06->@07->@08->@02->...(clear on sw off)
        // Cycle count to LED write: ~6 CPU cycles from poll
        // =========================================================
        switches = 16'b0000_0000_0000_0010; // switch[1] ON
        #3000;  // 30 CPU cycles - enough to write LED and loop back to poll
        $display("T=%0t  TEST1  leds=%h  (expect 000a)", $time, leds);
        switches = 16'd0;
        #2000;  // 20 CPU cycles - enough to clear and return to poll
        $display("T=%0t  TEST1 OFF leds=%h  (expect 0000)", $time, leds);

        // =========================================================
        // TEST 2: JALR  (Switch 2 -> encoded=2)
        // jal->subroutine sets x8=20, jalr returns -> SW x8 -> LED=0x0014
        // Path: @09->@0A(fall)->@0B->@0E->@0F->@0C->@0D->@02->...(clear)
        // =========================================================
        switches = 16'b0000_0000_0000_0100; // switch[2] ON
        #3000;
        $display("T=%0t  TEST2  leds=%h  (expect 0014)", $time, leds);
        switches = 16'd0;
        #2000;
        $display("T=%0t  TEST2 OFF leds=%h  (expect 0000)", $time, leds);

        // =========================================================
        // TEST 3: BLT taken  (Switch 3 -> encoded=3)
        // x6=5, x7=10, blt x6,x7 TAKEN -> x8=30 -> LED=0x001E
        // Path: @10->@11(fall)->@12->@13->@14(taken)->@17->@18->@19->@02
        // =========================================================
        switches = 16'b0000_0000_0000_1000; // switch[3] ON
        #3000;
        $display("T=%0t  TEST3  leds=%h  (expect 001e)", $time, leds);
        switches = 16'd0;
        #2000;
        $display("T=%0t  TEST3 OFF leds=%h  (expect 0000)", $time, leds);

        // =========================================================
        // TEST 4: BLT not taken  (Switch 4 -> encoded=4)
        // x6=10, x7=5, blt x6,x7 NOT taken -> x8=40 -> LED=0x0028
        // Path: @1A->@1B(fall)->@1C->@1D->@1E(not taken)->@1F->@20->@21->@02
        // =========================================================
        switches = 16'b0000_0000_0001_0000; // switch[4] ON
        #3000;
        $display("T=%0t  TEST4  leds=%h  (expect 0028)", $time, leds);
        switches = 16'd0;
        #2000;
        $display("T=%0t  TEST4 OFF leds=%h  (expect 0000)", $time, leds);

        // End simulation
        $display("All tests complete.");
        $stop;
    end

endmodule