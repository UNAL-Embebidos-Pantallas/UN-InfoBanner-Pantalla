module line_render (
    input wire clk_25MHz,
    input wire begin_in,
    output wire done_out,
    input wire [4:0] addr,
    input wire [6:0] pwm,
    output wire rgb_en,
    output wire [5:0] rgb,
);
    localparam px_per_row = 96;
    reg [6:0] px_to_shift = 0;
    reg [5:0] rgb = 0;
    reg done_reg = 0;
    assign done_out = done_reg; 

    always @(posedge clk_25MHz) begin
        if(begin_in)begin
            done_reg<=0;
            px_to_shift <= 0;
        end
        else if (px_to_shift != px_per_row) begin
            if (rgb_en == 1) begin
                rgb <= px_to_shift[5:0];
                rgb_en <= 0;
            end else begin
                rgb_en <= 1;
                px_to_shift <= px_to_shift + 1;
            end
        end 
        else    
            done_reg <= 1;
    end
endmodule