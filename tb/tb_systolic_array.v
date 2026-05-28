`timescale 1ns/1ps

module tb_systolic_array;

    parameter N           = 4;
    parameter DATA_WIDTH  = 8;
    parameter ACCUM_WIDTH = 32;

    reg                              clk;
    reg                              rst_n;
    reg  [(N*DATA_WIDTH)-1:0]        a_row_flat;
    reg  [(N*DATA_WIDTH)-1:0]        b_col_flat;
    reg                              valid_in;
    wire [(N*N*ACCUM_WIDTH)-1:0]     result_flat;
    wire [(N*N)-1:0]                 result_valid_flat;

    systolic_array #(
        .N           (N),
        .DATA_WIDTH  (DATA_WIDTH),
        .ACCUM_WIDTH (ACCUM_WIDTH)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .a_row_flat       (a_row_flat),
        .b_col_flat       (b_col_flat),
        .valid_in         (valid_in),
        .result_flat      (result_flat),
        .result_valid_flat(result_valid_flat)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    reg [DATA_WIDTH-1:0]  A [0:N-1][0:N-1];
    reg [DATA_WIDTH-1:0]  B [0:N-1][0:N-1];
    reg [ACCUM_WIDTH-1:0] C_ref [0:N-1][0:N-1];

    integer i, j, k, t, col, row;

    task compute_ref;
        begin
            for (i = 0; i < N; i = i + 1)
                for (j = 0; j < N; j = j + 1) begin
                    C_ref[i][j] = 0;
                    for (k = 0; k < N; k = k + 1)
                        C_ref[i][j] = C_ref[i][j] + A[i][k] * B[k][j];
                end
        end
    endtask

    task feed_inputs;
        begin
            for (t = 0; t < (2*N - 1); t = t + 1) begin
                for (i = 0; i < N; i = i + 1) begin
                    col = t - i;
                    if (col >= 0 && col < N)
                        a_row_flat[(i*DATA_WIDTH) +: DATA_WIDTH] = A[i][col];
                    else
                        a_row_flat[(i*DATA_WIDTH) +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                end
                for (j = 0; j < N; j = j + 1) begin
                    row = t - j;
                    if (row >= 0 && row < N)
                        b_col_flat[(j*DATA_WIDTH) +: DATA_WIDTH] = B[row][j];
                    else
                        b_col_flat[(j*DATA_WIDTH) +: DATA_WIDTH] = {DATA_WIDTH{1'b0}};
                end
                valid_in = 1;
                @(posedge clk); #1;
            end
            valid_in = 0;
        end
    endtask

    initial begin
        $dumpfile("tb_systolic_array.vcd");
        $dumpvars(0, tb_systolic_array);

        rst_n      = 0;
        valid_in   = 0;
        a_row_flat = 0;
        b_col_flat = 0;

        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;

        for (i = 0; i < N; i = i + 1)
            for (j = 0; j < N; j = j + 1)
                A[i][j] = (i == j) ? 8'd1 : 8'd0;

        for (i = 0; i < N; i = i + 1)
            for (j = 0; j < N; j = j + 1)
                B[i][j] = (i == j) ? 8'd1 : 8'd0;

        compute_ref;
        feed_inputs;
        repeat (N + 2) @(posedge clk);

        $display("=== Test 1: Identity x Identity ===");
        for (i = 0; i < N; i = i + 1)
            for (j = 0; j < N; j = j + 1)
                if (result_flat[((i*N+j)*ACCUM_WIDTH) +: ACCUM_WIDTH] === C_ref[i][j])
                    $display("  C[%0d][%0d] = %0d  PASS", i, j, result_flat[((i*N+j)*ACCUM_WIDTH) +: ACCUM_WIDTH]);
                else
                    $display("  C[%0d][%0d] = %0d  FAIL (expected %0d)", i, j, result_flat[((i*N+j)*ACCUM_WIDTH) +: ACCUM_WIDTH], C_ref[i][j]);

        rst_n = 0; @(posedge clk); #1; rst_n = 1;

        for (i = 0; i < N; i = i + 1)
            for (j = 0; j < N; j = j + 1) begin
                A[i][j] = $random % 8 + 1;
                B[i][j] = $random % 8 + 1;
            end

        compute_ref;
        feed_inputs;
        repeat (N + 2) @(posedge clk);

        $display("=== Test 2: Random Matrix ===");
        for (i = 0; i < N; i = i + 1)
            for (j = 0; j < N; j = j + 1)
                if (result_flat[((i*N+j)*ACCUM_WIDTH) +: ACCUM_WIDTH] === C_ref[i][j])
                    $display("  C[%0d][%0d] = %0d  PASS", i, j, result_flat[((i*N+j)*ACCUM_WIDTH) +: ACCUM_WIDTH]);
                else
                    $display("  C[%0d][%0d] = %0d  FAIL (expected %0d)", i, j, result_flat[((i*N+j)*ACCUM_WIDTH) +: ACCUM_WIDTH], C_ref[i][j]);

        $finish;
    end

endmodule
