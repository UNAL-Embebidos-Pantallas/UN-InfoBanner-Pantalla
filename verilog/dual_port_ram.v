module dual_port_ram #(parameter IMAGEN="image.mem")(
    input wire clk_a,
    input wire we_a,
    input [23:0] data_in_a,
    input [11:0]addr_a,

    input wire clk_b,
    input wire re_b,
    output reg [23:0] data_out_b,
    input [11:0]addr_b
);
reg [23:0] mem [2304:0];

initial begin
    $readmemb(IMAGEN,mem);
end

always @(posedge clk_a)
begin
    if (we_a) 
    mem[addr_a] <= data_in_a;
end

always @(posedge clk_b)
begin
	if (re_b)	
	data_out_b <= mem[addr_b];
end
endmodule