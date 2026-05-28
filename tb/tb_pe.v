`timescale 1ns/1ps

module tb_pe;

    parameter DATA_WIDTH  = 8;
    parameter ACCUM_WIDTH = 32;

    reg                    clk;
    reg                    rst_n;
    reg  [DATA_WIDTH-1:0]  a_in;
    reg  [DATA_WIDTH-1:0]  b_in;
    reg                    valid_in;
    wire [DATA_WIDTH-1:0]  a_out;
    wire [DATA_WIDTH-1:0]  b_out;
    wire                   valid_out;
    wire [ACCUM_WIDTH-1:0] result;
    wire                   result_valid;

    pe #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ACCUM_WIDTH (ACCUM_WIDTH)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .a_in        (a_in),
        .b_in        (b_in),
        .valid_in    (valid_in),
        .a_out       (a_out),
        .b_out       (b_out),
        .valid_out   (valid_out),
        .result      (result),
        .result_valid(result_valid)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer k;

    initial begin
        $dumpfile("tb_pe.vcd");
        $dumpvars(0, tb_pe);

        rst_n    = 0;
        a_in     = 0;
        b_in     = 0;
        valid_in = 0;

        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;

        for (k = 1; k <= 4; k = k + 1) begin
            a_in     = k;
            b_in     = k;
            valid_in = 1;
            @(posedge clk); #1;
        end

        valid_in = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;

        if (result === 32'd30)
            $display("PASS: result = %0d", result);
        else
            $display("FAIL: result = %0d, expected 30", result);

        $finish;
    end

endmodule
