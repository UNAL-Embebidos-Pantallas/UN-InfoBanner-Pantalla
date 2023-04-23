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
    output reg sclk, lat, oe, a, b, c, d,
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
assign sclk = clk_en & clk_25MHz;

// Iteration logic
reg [11:0] addr_b_reg;

always @(posedge clk) begin
  if (cnt_en) begin
    if (addr_b_reg == 2303)  // check if maximum address is reached
      addr_b_reg <= 0;  // wrap around to address 0
    else
      addr_b_reg <= addr_b_reg + 1;  // increment address
  end
end

assign addr_b = addr_b_reg;

// Memory
reg [11:0] addr_b;
reg [31: 0] data_in_b;
reg [31: 0] data_out_b, data_out_a;  
wire we_rgb = 0;
wire re_rgb = cnt_en;
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
reg busy_w;
wire RESET, clk_en;
reg cnt_en;
assign RESET = ~rst;

led_matrix_control #()
matrix_cntr(
    .clk(clk_25MHz),
    .rst(RESET),
    .CE(cnt_en),
    .clk_en(clk_en),
    .LAT(lat),
    .OE(oe),
    .busy(busy_w),
    .row_addr({a,b,c,d})
    );

assign rgb0 = data_out_b[0:15];
assign rgb1 = data_out_b[16:31];

endmodule