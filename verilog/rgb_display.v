`include "led_matrix_control.v"
`include "FD25MHz.v"
`include "line_render.v"
`include "dual_port_ram.v"

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
    input wire [11:0] data_in_a, 
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
reg [5:0] rgb;

// Memory
reg [11:0] addr_b;
reg [11:0] data_in_b;
reg [11:0] data_out_b, data_out_a;  
wire we_rgb = 0;
wire re_rgb;

reg clk_25MHz, rgb_en;

wire next_line_begin;
wire next_line_done;
reg [4:0] next_line_addr;
reg [6:0] next_line_pwm;

FD25MHz #()
freq_div(
    .i_clk(i_clk),
    .o_clk(clk_25MHz)
);

led_matrix_control #()
matrix_cntrl(
    .clk_25MHz(clk_25MHz),
    .row_addr(o_row_select),
    .blank(oe),
    .latch(lat),
    .next_line_begin(next_line_begin),
    .next_line_done(next_line_done),
    .next_line_addr(next_line_addr),
    .next_line_pwm(next_line_pwm),
    .ram_en(re_rgb)

);

line_render #()
line_rndr(
    .clk_25MHz(clk_25MHz),
    .begin_in(next_line_begin),
    .done_out(next_line_done),
    .addr(next_line_addr),
    .pwm(next_line_pwm),
    .rgb_en(rgb_en),
    .rgb(rgb),
    .buf_data(data_out_b),
    .buf_addr(addr_b)
);

dual_port_ram dual_ram(
    .clk_a(i_clk),
    .data_in_a(data_in_a),
    .we_a(wr_en),
    .re_a(rd_en),
    .addr_a(addr_a),
    .data_out_a(data_out_a),
    .clk_b(clk_25MHz),
    .data_out_b(data_out_b),
    .re_b(re_rgb),
    .we_b(we_rgb),
    .data_in_b(data_in_b),
    .addr_b(addr_b)
);

assign sclk = rgb_en;

// Wire RGB0-RGB1

assign o_data_r = {rgb[5], rgb[2]};
assign o_data_g = {rgb[4], rgb[1]};
assign o_data_b = {rgb[3], rgb[0]};

assign r0 = o_data_r[1];
assign g0 = o_data_g[1];
assign b0 = o_data_b[1];
assign r1 = o_data_r[0];
assign g1 = o_data_g[0];
assign b1 = o_data_b[0];

endmodule