module dual_port_memory #(
    parameter WIDTH = 96,
    parameter HEIGHT = 48,
    parameter BPP = 12, // Bits per pixel
    parameter BPC = 4, // Bits per color channel
    parameter CHAINED = 1 // Number of panels in chain
) (
    input rst,
    input clk,
    input wire [11:0] addr_a, addr_b, 
    input wire [31: 0] dat_in_a, dat_in_b, 
    input wire we_a, we_b,
    input wire re_a, re_b,   
    output reg [31:0] dat_out_a, dat_out_b 
);

// Dual port RAM with 2304x32 bits resolution
reg [31:0] mem [0:(CHAINED*WIDTH*HEIGHT)/2-1];

// Initialize memory to 0 on reset
// initial begin
//   if (rst) begin
//     for (integer i = 0; i < CHAINED*WIDTH*HEIGHT; i++) begin
//       mem[i] <= 0;
//     end
//   end
// end

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