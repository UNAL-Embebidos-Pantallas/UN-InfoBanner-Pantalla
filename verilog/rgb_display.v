`include "led_matrix_control.v"
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
    input wire [11:0] addr_a,
    input wire [31: 0] data_in_a, 
    input wire wr_en,
    input wire rd_en,
    
    // LED panel HUB75 IO
    output reg sclk, lat, oe, a, b, c, d, e,
    output reg r0, g0, b0, r1, g1, b1 
);

// Frequency divider
reg [1:0] count;
reg clk_25MHz;

always @(posedge clk) begin
  count <= count + 1;
  if (count == 2) begin
    count <= 0;
    clk_25MHz <= ~clk_25MHz;
  end
end

// Memory
reg [11:0] addr_b;
reg [31: 0] data_in_b;
reg [31: 0] data_out_b, data_out_a;  
wire we_rgb = 0;
wire re_rgb;
reg [15:0] rgb0, rgb1;

dual_port_memory #(
    .WIDTH(WIDTH), 
    .HEIGHT(HEIGHT), 
    .BPP(BPP), 
    .CHAINED(CHAINED)
    ) 
dual_mem(
    .rst(rst), 
    .clk(clk), 
    .addr_a(addr_a), .addr_b(addr_b), 
    .dat_in_a(data_in_a), .dat_in_b(data_in_b),
    .dat_out_a(data_out_a), .dat_out_b(data_out_b),
    .we_a(wr_en), .we_b(we_rgb), 
    .re_a(rd_en), .re_b(re_rgb)
    );

// Led control

led_matrix_control #()
matrix_cntr(
    .clk(clk_25MHz),
    .addr_out(addr_b),
    .data_in_rgb0(rgb0),
    .data_in_rgb1(rgb1),
    .rd_en(re_rgb),
    .sclk(sclk),
    .latch(lat),
    .OE(oe),
    .r_data({r1, r0}),
    .g_data({g1, g0}),
    .b_data({b1, b0}),
    .row_sel({a,b,c,d,e})
    );

assign rgb0 = data_out_b[0:15];
assign rgb1 = data_out_b[16:31];

endmodule