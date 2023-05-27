module dual_port_memory #()(
    input rst,
    input clk,
    input wire [11:0] addr_a, addr_b, 
    input wire [23:0] dat_in_a, dat_in_b, 
    input wire we_a, we_b,
    input wire re_a, re_b,   
    output reg [23:0] dat_out_a, dat_out_b 
);

// Dual port RAM with 2304x24 bits resolution
reg [23:0] mem [2304:0];

initial begin
    $readmemh("image.mem", mem);
end

// Port A Write and Read
always @ (posedge clk)
begin
    if (we_a) 
    begin
        mem[addr_a] <= dat_in_a;
    end
    else if (re_a)
    begin
        dat_out_a <= mem[addr_a];
    end
end

// Port B Write and Read
always @ (posedge clk)
begin
    if (we_b) 
    begin
        mem[addr_b] <= dat_in_b;
    end
    else if (re_b)
    begin
        dat_out_b <= mem[addr_b];
    end
end

endmodule