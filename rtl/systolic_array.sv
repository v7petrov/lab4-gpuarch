module systolic_array #(
    parameter int N = 4,
    parameter int DATA_WIDTH = 16
)(
    input  wire clk,
    input  wire reset,

    input  wire [DATA_WIDTH-1:0] a_in_row [0:N-1],
    input  wire [DATA_WIDTH-1:0] b_in_col [0:N-1],
    input  wire                  valid_in,

    output wire [2*DATA_WIDTH-1:0] c_out [0:N-1][0:N-1],
    output wire                    valid_out
);

    wire [DATA_WIDTH-1:0] a_wire     [0:N-1][0:N-1];
    wire [DATA_WIDTH-1:0] b_wire     [0:N-1][0:N-1];
    wire                  valid_wire [0:N-1][0:N-1];

    genvar i, j;
    generate
        for (i = 0; i < N; i++) begin : rows
            for (j = 0; j < N; j++) begin : cols

                wire [DATA_WIDTH-1:0] a_in_sel;
                wire [DATA_WIDTH-1:0] b_in_sel;
                wire                  valid_in_sel;

                // A comes from left (or external input if first column)
                assign a_in_sel =
                    (j == 0) ? a_in_row[i] :
                               a_wire[i][j-1];

                // B comes from top (or external input if first row)
                assign b_in_sel =
                    (i == 0) ? b_in_col[j] :
                               b_wire[i-1][j];

                // Valid propagation (wavefront)
                assign valid_in_sel =
                    (i == 0 && j == 0) ? valid_in :
                    (j == 0)          ? valid_wire[i-1][j] :
                                        valid_wire[i][j-1];

                PE #(.DATA_WIDTH(DATA_WIDTH)) pe (
                    .clk(clk),
                    .reset(reset),

                    .a_in(a_in_sel),
                    .b_in(b_in_sel),
                    .valid_in(valid_in_sel),

                    .a_out(a_wire[i][j]),
                    .b_out(b_wire[i][j]),
                    .valid_out(valid_wire[i][j]),
                    .c_out(c_out[i][j])
                );

            end
        end
    endgenerate

    assign valid_out = valid_wire[N-1][N-1];

endmodule