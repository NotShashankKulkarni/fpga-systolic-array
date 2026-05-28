module input_skew #(
    parameter N          = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire [(N*N*DATA_WIDTH)-1:0]   a_flat,
    input  wire [(N*N*DATA_WIDTH)-1:0]   b_flat,
    input  wire                          valid_in,
    output reg  [(N*DATA_WIDTH)-1:0]     a_skewed_flat,
    output reg  [(N*DATA_WIDTH)-1:0]     b_skewed_flat,
    output reg                           valid_out
);

    localparam DEPTH = 2*N - 1;
    localparam CTR_W = $clog2(DEPTH) + 1;

    reg [CTR_W-1:0] ctr;
    reg             active;

    reg [DATA_WIDTH-1:0] a_shift [0:N-1][0:N-1];
    reg [DATA_WIDTH-1:0] b_shift [0:N-1][0:N-1];

    wire [DATA_WIDTH-1:0] a_in [0:N-1][0:N-1];
    wire [DATA_WIDTH-1:0] b_in [0:N-1][0:N-1];

    genvar gi, gj;

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : unpack_a
            for (gj = 0; gj < N; gj = gj + 1) begin : unpack_a_col
                assign a_in[gi][gj] = a_flat[((gi*N+gj)*DATA_WIDTH) +: DATA_WIDTH];
            end
        end
    endgenerate

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : unpack_b
            for (gj = 0; gj < N; gj = gj + 1) begin : unpack_b_col
                assign b_in[gi][gj] = b_flat[((gi*N+gj)*DATA_WIDTH) +: DATA_WIDTH];
            end
        end
    endgenerate

    integer ii, jj, kk;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctr       <= {CTR_W{1'b0}};
            active    <= 1'b0;
            valid_out <= 1'b0;
        end else if (valid_in && !active) begin
            active    <= 1'b1;
            ctr       <= {CTR_W{1'b0}};
            valid_out <= 1'b1;
        end else if (active) begin
            if (ctr == DEPTH - 1) begin
                active    <= 1'b0;
                valid_out <= 1'b0;
                ctr       <= {CTR_W{1'b0}};
            end else begin
                ctr       <= ctr + 1;
                valid_out <= 1'b1;
            end
        end else begin
            valid_out <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (ii = 0; ii < N; ii = ii + 1)
                for (jj = 0; jj < N; jj = jj + 1) begin
                    a_shift[ii][jj] <= {DATA_WIDTH{1'b0}};
                    b_shift[ii][jj] <= {DATA_WIDTH{1'b0}};
                end
        end else begin
            for (ii = 0; ii < N; ii = ii + 1) begin
                a_shift[ii][0] <= (ctr >= ii) ? a_in[ii][ctr - ii] : {DATA_WIDTH{1'b0}};
                b_shift[0][ii] <= (ctr >= ii) ? b_in[ctr - ii][ii] : {DATA_WIDTH{1'b0}};
                for (jj = 1; jj < N; jj = jj + 1) begin
                    a_shift[ii][jj] <= a_shift[ii][jj-1];
                    b_shift[jj][ii] <= b_shift[jj-1][ii];
                end
            end
        end
    end

    always @(*) begin
        for (kk = 0; kk < N; kk = kk + 1) begin
            a_skewed_flat[(kk*DATA_WIDTH) +: DATA_WIDTH] = (kk == 0) ? a_shift[0][0] : a_shift[kk][kk-1];
            b_skewed_flat[(kk*DATA_WIDTH) +: DATA_WIDTH] = (kk == 0) ? b_shift[0][0] : b_shift[kk][kk-1];
        end
    end

endmodule
