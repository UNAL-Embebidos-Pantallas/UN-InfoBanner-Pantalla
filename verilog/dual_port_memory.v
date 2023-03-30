module dual_port_memory #(
    parameter WIDTH = 128,
    parameter HEIGHT = 64,
    parameter BPP = 12, // Bits per pixel
    parameter BPC = 4, // Bits per color channel
    parameter CHAINED = 1 // Number of panels in chain
) (
    input rst,
    input clk,
    input wire [13:0] addr_a, addr_b, 
    input wire [BPP-1: 0] dat_in_a, dat_in_b, 
    input wire we_a, we_b,
    input wire re_a, re_b,   
    output reg [BPP-1:0] dat_out_a, dat_out_b 
);

// Dual port RAM with 8192x12 bits resolution
reg [BPP-1:0] mem [0:CHAINED*WIDTH*HEIGHT-1];

// Port A Write and Read
always @ (posedge clk)
begin
    if (we_a) 
    begin
        mem[addr_a] <= dat_in_a;
        dat_out_a <= dat_in_a;
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
        dat_out_b <= dat_in_b;
    end
    else if (re_b)
    begin
        dat_out_b <= mem[addr_b];
    end
end

endmodule