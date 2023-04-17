`default_nettype none
module rgb_display #(
    parameter WIDTH = 96,
    parameter HEIGHT = 48,
    parameter BPP = 12, // Bits per pixel
    parameter BPC = 4, // Bits per color channel
    parameter CHAINED = 1 // Number of panels in chain
)
(   //Interface
    input wire clk, 
    input wire rst, 

    // Memory IO
    input wire [13:0] addr, 
    input wire [BPP-1: 0] data_in, 
    output reg [BPP-1: 0] data_out,
    input wire wr_en,
    input wire rd_en,
    
    // LED panel HUB75 IO
    output reg sclk, lat, oe, a, b, c, d,
    output reg r0, g0, b0, r1, g1, b1 
);

// Memory signals
wire [13:0] addr_rgb;
wire [BPP-1: 0] data_out_rgb, data_in_rgb, dat_out_pro;
wire we_rgb, re_rgb;

dual_port_memory #(
    .WIDTH(WIDTH), 
    .HEIGHT(HEIGHT), 
    .BPP(BPP), 
    .CHAINED(CHAINED)
    ) 
dual_mem(
    .rst(rst), 
    .clk(clk), 
    .addr_a(addr), .addr_b(addr_rgb), 
    .dat_in_a(data_in), .dat_in_b(data_in_rgb),
    .dat_out_a(dat_out_pro), .dat_out_b(data_out_rgb),
    .we_a(wr_en), .we_b(we_rgb), 
    .re_a(rd_en), .re_b(re_rgb)
    );

endmodule