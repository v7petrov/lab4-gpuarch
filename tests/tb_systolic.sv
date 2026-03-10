`timescale 1ns/1ps

module tb_systolic;

    localparam N          = 4;
    localparam DATA_WIDTH = 16;
    localparam CLK_HALF   = 5;

    localparam FEED_CYCLES  = 2*N - 1;   // 7
    localparam DRAIN_CYCLES = 2*(N-1) + 1 + N; // 10

    reg                    clk;
    reg                    reset;
    reg  [DATA_WIDTH-1:0]  a_in_row [0:N-1];
    reg  [DATA_WIDTH-1:0]  b_in_col [0:N-1];
    reg                    valid_in;

    wire [2*DATA_WIDTH-1:0] c_out [0:N-1][0:N-1];
    wire                    valid_out;

    systolic_array #(.N(N), .DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .reset(reset),
        .a_in_row(a_in_row), .b_in_col(b_in_col),
        .valid_in(valid_in),
        .c_out(c_out), .valid_out(valid_out)
    );

    initial clk = 0;
    always #CLK_HALF clk = ~clk;

    reg [DATA_WIDTH-1:0]   A     [0:N-1][0:N-1];
    reg [DATA_WIDTH-1:0]   B     [0:N-1][0:N-1];
    reg [2*DATA_WIDTH-1:0] C_exp [0:N-1][0:N-1];

    reg [DATA_WIDTH-1:0] a_skew [0:N-1][0:FEED_CYCLES-1]; // a_skew[row][t]
    reg [DATA_WIDTH-1:0] b_skew [0:N-1][0:FEED_CYCLES-1]; // b_skew[col][t]

    integer i, j, k, t, errors, cycle;

    initial begin
        $dumpfile("tb_systolic.vcd");
        $dumpvars(0, tb_systolic);

        A[0][0]=1;  A[0][1]=2;  A[0][2]=3;  A[0][3]=4;
        A[1][0]=5;  A[1][1]=6;  A[1][2]=7;  A[1][3]=8;
        A[2][0]=9;  A[2][1]=10; A[2][2]=11; A[2][3]=12;
        A[3][0]=13; A[3][1]=14; A[3][2]=15; A[3][3]=16;

        B[0][0]=1; B[0][1]=0; B[0][2]=0; B[0][3]=0;
        B[1][0]=0; B[1][1]=1; B[1][2]=0; B[1][3]=0;
        B[2][0]=0; B[2][1]=0; B[2][2]=1; B[2][3]=0;
        B[3][0]=0; B[3][1]=0; B[3][2]=0; B[3][3]=1;

        for (i = 0; i < N; i = i+1)
            for (j = 0; j < N; j = j+1) begin
                C_exp[i][j] = 0;
                for (k = 0; k < N; k = k+1)
                    C_exp[i][j] = C_exp[i][j] + A[i][k] * B[k][j];
            end

        for (i = 0; i < N; i = i+1)
            for (t = 0; t < FEED_CYCLES; t = t+1) begin
                if (t >= i && (t - i) < N)
                    a_skew[i][t] = A[i][t - i];
                else
                    a_skew[i][t] = 0;
            end

        for (j = 0; j < N; j = j+1)
            for (t = 0; t < FEED_CYCLES; t = t+1) begin
                if (t >= j && (t - j) < N)
                    b_skew[j][t] = B[t - j][j];
                else
                    b_skew[j][t] = 0;
            end

        reset = 1; valid_in = 0;
        a_in_row[0]=0; a_in_row[1]=0; a_in_row[2]=0; a_in_row[3]=0;
        b_in_col[0]=0; b_in_col[1]=0; b_in_col[2]=0; b_in_col[3]=0;
        repeat (3) @(negedge clk);
        reset = 0;

        for (cycle = 0; cycle < FEED_CYCLES; cycle = cycle+1) begin
            @(negedge clk);
            valid_in    = 1;
            a_in_row[0] = a_skew[0][cycle];
            a_in_row[1] = a_skew[1][cycle];
            a_in_row[2] = a_skew[2][cycle];
            a_in_row[3] = a_skew[3][cycle];
            b_in_col[0] = b_skew[0][cycle];
            b_in_col[1] = b_skew[1][cycle];
            b_in_col[2] = b_skew[2][cycle];
            b_in_col[3] = b_skew[3][cycle];
        end

        @(negedge clk);
        valid_in    = 0;
        a_in_row[0]=0; a_in_row[1]=0; a_in_row[2]=0; a_in_row[3]=0;
        b_in_col[0]=0; b_in_col[1]=0; b_in_col[2]=0; b_in_col[3]=0;

        repeat (DRAIN_CYCLES) @(posedge clk);
        @(negedge clk);

        errors = 0;
        $display("=== Results ===");
        for (i = 0; i < N; i = i+1)
            for (j = 0; j < N; j = j+1) begin
                if (c_out[i][j] !== C_exp[i][j]) begin
                    $display("FAIL C[%0d][%0d] = %0d, expected %0d",
                             i, j, c_out[i][j], C_exp[i][j]);
                    errors = errors + 1;
                end else
                    $display("OK   C[%0d][%0d] = %0d", i, j, c_out[i][j]);
            end

        if (errors == 0)
            $display("ALL PASS");
        else
            $display("%0d FAILURES", errors);

        $finish;
    end

endmodule