`timescale 1ns/1ps
module PE_tb;

    localparam DATA_WIDTH = 16;
    localparam CLK_PERIOD = 10;

    logic clk, rst;

    logic [DATA_WIDTH-1:0] a_in, b_in;
    logic [DATA_WIDTH-1:0] a_out, b_out;
    logic valid_in, valid_out;
    logic [2*DATA_WIDTH-1:0] c_out;

    PE #(.DATA_WIDTH(DATA_WIDTH)) pe_inst (
        .clk(clk),
        .reset(rst),
        .a_in(a_in),
        .b_in(b_in),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .a_out(a_out),
        .b_out(b_out),
        .c_out(c_out)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $dumpfile("PE_tb.vcd");
        $dumpvars(0, PE_tb);
    end

    task automatic test_PE(
        input logic [DATA_WIDTH-1:0] a_arr[],
        input logic [DATA_WIDTH-1:0] b_arr[],
        input int unsigned len
    );
        logic [2*DATA_WIDTH-1:0] exp_c;
        exp_c = 0;
        a_in = 0; b_in = 0; valid_in = 0;

        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        @(negedge clk);
        a_in     <= a_arr[0];
        b_in     <= b_arr[0];
        valid_in <= 1;

        for (int i = 0; i < len; i++) begin
            @(posedge clk);  
            exp_c += a_arr[i] * b_arr[i];
            @(negedge clk);
            if (valid_out !== 1)
                $error("valid_out wrong at i=%0d", i);
            if (a_out !== a_arr[i])
                $error("a_out mismatch at i=%0d exp=%0d got=%0d", i, a_arr[i], a_out);
            if (b_out !== b_arr[i])
                $error("b_out mismatch at i=%0d exp=%0d got=%0d", i, b_arr[i], b_out);
            if (c_out !== exp_c)
                $error("c_out mismatch at i=%0d exp=%0d got=%0d", i, exp_c, c_out);

            if (i+1 < len) begin
                a_in     <= a_arr[i+1];
                b_in     <= b_arr[i+1];
                valid_in <= 1;
            end else begin
                a_in     <= 0;
                b_in     <= 0;
                valid_in <= 0;
            end
        end

        // final: valid_out should drop one cycle after valid_in drops
        @(posedge clk);
        @(negedge clk);
        if (valid_out !== 0)
            $error("valid_out should be 0 after stream ends");

        if (c_out !== exp_c)
            $error("Final c_out mismatch exp=%0d got=%0d", exp_c, c_out);

        $display("Test finished. Final c_out = %0d", c_out);
    endtask

    initial begin
        logic [DATA_WIDTH-1:0] A[];
        logic [DATA_WIDTH-1:0] B[];

        A = new[5];
        B = new[5];

        A[0]=3;  B[0]=4;
        A[1]=5;  B[1]=6;
        A[2]=7;  B[2]=8;
        A[3]=2;  B[3]=9;
        A[4]=1;  B[4]=10;

        test_PE(A, B, 5);

        $display("DONE");
        $finish;
    end

endmodule