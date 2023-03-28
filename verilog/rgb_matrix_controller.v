module rgb_matrix_controller #(
    parameter WIDTH = 128,
    parameter HEIGHT = 64,
    parameter BPP = 12,
    parameter BPC = 4,
    parameter CHAINED = 1 // number of panels in chain
)
(
    input wire clk, 
    input wire rst, 

    input wire [13:0] addr, 
    input wire [BPP-1: 0] rgb_indat, 
    output wire [BPP-1: 0] rgb_outdat, // Modified to be inout for peripheral access 
    input wire wr_en,
    input wire rd_en, // Added input for processor read

    output reg sclk, lat, oe, a, b, c, d,
    output reg r0, g0, b0, r1, g1, b1 
);
// Dual port RAM with 8192x12 bits resolution
reg [BPP-1:0] mem [0:CHAINED*WIDTH*HEIGHT-1];

// Write to memory
always @(posedge clk) begin
    if (wr_en) begin
        mem[addr] <= rgb_indat;
    end
end

// Read to memory
always @(posedge clk) begin
    if (rd_en) begin
        mem[addr] <= rgb_outdat;
    end
end

endmodule