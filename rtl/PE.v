module PE #(
    parameter DATA_WIDTH = 16
)(
    input   wire                      clk, reset,
    input   wire [DATA_WIDTH-1:0]     a_in, b_in,

    input   wire                      valid_in, 
    output  reg                      valid_out,

    output  reg [DATA_WIDTH-1:0]     a_out, b_out,

    output  reg [2*DATA_WIDTH-1:0]    c_out
);

    always @(posedge clk) begin
        if (reset) begin
            valid_out <= 0;
            a_out     <= 0;
            b_out     <= 0;
            c_out     <= 0;
        end

        if (valid_in) begin
            c_out <= c_out + a_in * b_in;

            a_out <= a_in;
            b_out <= b_in;
        end

        valid_out <= valid_in;
    end
    
endmodule