`timescale 1ns / 1ps
module rgb_matrix_controller(
    input clk,
    input wr_enable,
    input rst,
    input [11:0] RGB_data,

    output reg sclk, latch, blank, R0, G0, B0, R1, G1, B1,
    output reg [4:0] address_row
);
    
endmodule