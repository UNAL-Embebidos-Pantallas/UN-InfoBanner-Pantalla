module dual_port_ram #(parameter IMAGEN="image.mem")(
    input wire clk_a,
    input wire we_a, re_a,
    input [23:0] data_in_a,
    input [11:0]addr_a,
    output reg [23:0] data_out_a,

    input wire clk_b,
    input wire re_b, we_b,
    input [23:0] data_in_b,
    output reg [23:0] data_out_b,
    input [11:0]addr_b
);
reg [23:0] mem [2303:0];

initial begin
    $readmemb(IMAGEN,mem);
end

always @(posedge clk_a)
begin
    if (we_a) 
    mem[addr_a] <= data_in_a;
    else if (re_a) 
    data_out_a <= mem[addr_a];
end

always @(posedge clk_b)
begin
	if (re_b)	
	data_out_b <= mem[addr_b];
    else if (we_b) 
    mem[addr_b] <= data_in_b;
end
endmodule