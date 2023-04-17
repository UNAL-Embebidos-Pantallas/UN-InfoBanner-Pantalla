`default_nettype none
module rgb_display #(
    parameter WIDTH = 128,
    parameter HEIGHT = 64,
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

wire ce;
wire clk_en;
wire RESET;
reg clk_so;
assign RESET = ~rst;
assign clk_out = clk_en & clk_so;

// Clock Divider (100 MHz -> 25 MHz)
always @(posedge clk, posedge RESET) begin
    if (RESET) begin
        clk_so <= 0;
    end else begin
        // Contador de ciclos de reloj de entrada (100 MHz)
        if (count == 4) begin
            count <= 0;
            clk_so <= ~clk_so; // Cambiar el estado del reloj dividido cada 4 flancos de subida del reloj de entrada
        end else begin
            count <= count + 1;
        end
    end
end

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