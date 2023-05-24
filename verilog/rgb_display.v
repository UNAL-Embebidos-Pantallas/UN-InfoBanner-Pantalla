`include "led_matrix_control.v"
module rgb_display #(
    parameter WIDTH = 96,
    parameter HEIGHT = 48,
    parameter BPP = 12, // Bits per pixel
    parameter CHAINED = 1 // Number of panels in chain
)(
    // Input clock to our panel driver
    input wire i_clk,
    input wire i_rst,

    // Memory IO
    input wire [11:0] addr_a,
    input wire [23:0] data_in_a, 
    input wire wr_en,
    input wire rd_en,
    
    // LED panel HUB75 IO
    output reg sclk, lat, oe,
    output reg r0, g0, b0, r1, g1, b1 ,
    output reg [4:0] o_row_select,

);

reg [1:0] o_data_r;
reg [1:0] o_data_g;
reg [1:0] o_data_b;

// Memory
reg [11:0] addr_b;
reg [23: 0] data_in_b;
reg [23: 0] data_out_b, data_out_a;  
wire we_rgb = 0;
wire re_rgb;

reg [1:0] count;
reg clk_25MHz;

always @(posedge i_clk) begin
    count <= count + 1;
    if (count == 2) begin
        count <= 0;
        clk_25MHz <= ~clk_25MHz;
    end
end

dual_port_memory #(
    .WIDTH(WIDTH), 
    .HEIGHT(HEIGHT), 
    .BPP(BPP), 
    .CHAINED(CHAINED)
    ) 
dual_mem(
    .rst(i_rst), 
    .clk(i_clk), 
    .addr_a(addr_a), .addr_b(addr_b), 
    .dat_in_a(data_in_a), .dat_in_b(data_in_b),
    .dat_out_a(data_out_a), .dat_out_b(data_out_b),
    .we_a(wr_en), .we_b(we_rgb), 
    .re_a(rd_en), .re_b(re_rgb)
    );

led_matrix_control #()
matrix_cntrl(
    .i_clk(clk_25MHz),
    .i_rst(i_rst),
    // .o_ram_addr(addr_b),
    // .i_ram_b1_data(data_out_b[23:12]),
    // .i_ram_b2_data(data_out_b[11:0]),
    // .o_ram_read_stb(re_rgb),
    .o_data_clock(sclk),
    .o_data_latch(lat),
    .o_data_blank(oe),
    .o_data_r(o_data_r),
    .o_data_b(o_data_b),
    .o_data_g(o_data_g),
    .o_row_select(o_row_select)
    );

// Wire RGB0-RGB1
assign r0 = o_data_r[0];
assign g0 = o_data_g[0];
assign b0 = o_data_b[0];
assign r1 = o_data_r[1];
assign g1 = o_data_g[1];
assign b1 = o_data_b[1];

endmodule