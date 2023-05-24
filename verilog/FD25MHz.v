module FD25MHz #(
)(
    input wire i_clk,
    output wire o_clk,
);

reg [1:0] count;
reg clk_25MHz;

always @(posedge i_clk) begin
    count <= count + 1;
    if (count == 2) begin
        count <= 0;
        clk_25MHz <= ~clk_25MHz;
    end
end

assign o_clk = clk_25MHz;

endmodule