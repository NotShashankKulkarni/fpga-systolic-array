module systolic_array #(
    parameter N           = 4,
    parameter DATA_WIDTH  = 8,
    parameter ACCUM_WIDTH = 32
)(
    input  wire                                          clk,
    input  wire                                          rst_n,
    input  wire [(N*DATA_WIDTH)-1:0]                     a_row_flat,
    input  wire [(N*DATA_WIDTH)-1:0]                     b_col_flat,
    input  wire                                          valid_in,
    output wire [(N*N*ACCUM_WIDTH)-1:0]                  result_flat,
    output wire [(N*N)-1:0]                              result_valid_flat
);

    wire [DATA_WIDTH-1:0] a_wire [0:N][0:N-1];
    wire [DATA_WIDTH-1:0] b_wire [0:N-1][0:N];
    wire                  va_wire[0:N][0:N-1];
    wire                  vb_wire[0:N-1][0:N];

    genvar i, j;

    generate
        for (i = 0; i < N; i = i + 1) begin : gen_a_in
            assign a_wire[i][0]  = a_row_flat[(i*DATA_WIDTH) +: DATA_WIDTH];
            assign va_wire[i][0] = valid_in;
        end
    endgenerate

    generate
        for (j = 0; j < N; j = j + 1) begin : gen_b_in
            assign b_wire[0][j]  = b_col_flat[(j*DATA_WIDTH) +: DATA_WIDTH];
            assign vb_wire[0][j] = valid_in;
        end
    endgenerate

    generate
        for (i = 0; i < N; i = i + 1) begin : gen_rows
            for (j = 0; j < N; j = j + 1) begin : gen_cols

                wire [DATA_WIDTH-1:0]  a_out_w;
                wire [DATA_WIDTH-1:0]  b_out_w;
                wire                   valid_out_w;
                wire [ACCUM_WIDTH-1:0] result_w;
                wire                   result_valid_w;

                pe #(
                    .DATA_WIDTH  (DATA_WIDTH),
                    .ACCUM_WIDTH (ACCUM_WIDTH)
                ) u_pe (
                    .clk         (clk),
                    .rst_n       (rst_n),
                    .a_in        (a_wire[i][j]),
                    .b_in        (b_wire[i][j]),
                    .valid_in    (va_wire[i][j] & vb_wire[i][j]),
                    .a_out       (a_out_w),
                    .b_out       (b_out_w),
                    .valid_out   (valid_out_w),
                    .result      (result_w),
                    .result_valid(result_valid_w)
                );

                assign a_wire[i][j+1]  = a_out_w;
                assign b_wire[i+1][j]  = b_out_w;
                assign va_wire[i][j+1] = valid_out_w;
                assign vb_wire[i+1][j] = valid_out_w;

                assign result_flat[((i*N+j)*ACCUM_WIDTH) +: ACCUM_WIDTH] = result_w;
                assign result_valid_flat[i*N+j]                           = result_valid_w;

            end
        end
    endgenerate

endmodule
