module pe #(
    parameter DATA_WIDTH  = 8,
    parameter ACCUM_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [DATA_WIDTH-1:0]   a_in,
    input  wire [DATA_WIDTH-1:0]   b_in,
    input  wire                    valid_in,
    output reg  [DATA_WIDTH-1:0]   a_out,
    output reg  [DATA_WIDTH-1:0]   b_out,
    output reg                     valid_out,
    output reg  [ACCUM_WIDTH-1:0]  result,
    output reg                     result_valid
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out     <= {DATA_WIDTH{1'b0}};
            b_out     <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            a_out     <= a_in;
            b_out     <= b_in;
            valid_out <= valid_in;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result       <= {ACCUM_WIDTH{1'b0}};
            result_valid <= 1'b0;
        end else if (valid_in) begin
            result       <= result + (a_in * b_in);
            result_valid <= 1'b1;
        end
    end

endmodule
