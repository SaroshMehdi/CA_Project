`timescale 1ns / 1ps
module tb_TaskB;

    reg         clk      = 0;
    reg         rst      = 1;
    reg  [15:0] switches = 16'd0;
    wire [15:0] leds;
    wire [6:0]  seg;
    wire [3:0]  an;

    always #5 clk = ~clk;

    SingleCycle dut (
        .clk     (clk),
        .rst     (rst),
        .switches(switches),
        .leds    (leds),
        .seg     (seg),
        .an      (an)
    );

    task wait_for_led;
        input [15:0] expected;
        input [31:0] timeout_cycles;
        integer i;
        begin
            i = 0;
            while (leds !== expected && i < timeout_cycles) begin
                @(posedge clk);
                i = i + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_TaskB.vcd");
        $dumpvars(0, tb_TaskB);

        rst = 1;
        switches = 16'd0;
        repeat(10) @(posedge clk);
        rst = 0;
        repeat(5) @(posedge clk);

        // CASE 1 - SLLI: expect LEDs = 10
        switches = 16'b0000_0000_0000_0010;
        wait_for_led(16'd10, 5000);
        repeat(200) @(posedge clk);
        switches = 16'd0;
        repeat(100) @(posedge clk);

        // CASE 2 - JALR: expect LEDs = 20
        switches = 16'b0000_0000_0000_0100;
        wait_for_led(16'd20, 5000);
        repeat(200) @(posedge clk);
        switches = 16'd0;
        repeat(100) @(posedge clk);

        // CASE 3 - BLT taken: expect LEDs = 30
        switches = 16'b0000_0000_0000_1000;
        wait_for_led(16'd30, 5000);
        repeat(200) @(posedge clk);
        switches = 16'd0;
        repeat(100) @(posedge clk);

        // CASE 4 - BLT not taken: expect LEDs = 40
        switches = 16'b0000_0000_0001_0000;
        wait_for_led(16'd40, 5000);
        repeat(200) @(posedge clk);
        switches = 16'd0;
        repeat(100) @(posedge clk);

        // CASE 5 - default: expect LEDs = 0
        switches = 16'd0;
        wait_for_led(16'd0, 5000);
        repeat(200) @(posedge clk);

        $finish;
    end

    initial begin
        #5_000_000;
        $finish;
    end

endmodule