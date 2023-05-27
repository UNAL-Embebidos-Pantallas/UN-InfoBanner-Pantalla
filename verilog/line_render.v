module line_render (
    input wire clk_25MHz,
    input wire begin_in,
    output wire done_out,
    input wire [4:0] addr,
    input wire [3:0] pwm,
    output wire rgb_en,
    output wire [5:0] rgb,
    //Memory I/O
    input wire [23:0]buf_data,
    output wire [11:0]buf_addr,
);
    localparam px_per_row = 96;
    reg [6:0] px_to_shift = 0;
    reg [5:0] rgb = 0;
    reg done_reg = 0;
    reg [3:0] pwm_counter;
    assign done_out = done_reg; 
    assign pwm_counter = pwm;

    reg [3:0] r0_data=0;
    reg [3:0] g0_data=0;
    reg [3:0] b0_data=0;

    reg [3:0] r1_data=0;
    reg [3:0] g1_data=0;
    reg [3:0] b1_data=0;

    reg r0_reg = 0;
    reg g0_reg = 0;
    reg b0_reg = 0;
    reg r1_reg = 0;
    reg g1_reg = 0;
    reg b1_reg = 0;

    always @(posedge clk_25MHz) begin
        if(begin_in)begin
            done_reg<=0;
            px_to_shift <= 0;
        end
        else if (px_to_shift != px_per_row) begin
            buf_addr <= px_to_shift+96*addr;
            r0_data <= buf_data[23:20];
            g0_data <= buf_data[19:16];
            b0_data <= buf_data[15:12];
            r1_data <= buf_data[11:8];
            g1_data <= buf_data[7:4];
            b1_data <= buf_data[3:0];
            // r0_data={px_to_shift[0],px_to_shift[0],px_to_shift[0],px_to_shift[0]};
            // g0_data={px_to_shift[1],px_to_shift[1],px_to_shift[1],px_to_shift[1]};
            // b0_data={px_to_shift[2],px_to_shift[2],px_to_shift[2],px_to_shift[2]};

            // r1_data={px_to_shift[3],px_to_shift[3],px_to_shift[3],px_to_shift[3]};
            // g1_data={px_to_shift[4],px_to_shift[4],px_to_shift[4],px_to_shift[4]};
            // b1_data={px_to_shift[5],px_to_shift[5],px_to_shift[5],px_to_shift[5]};
            if (rgb_en == 1) begin
                r0_reg = (pwm_counter<r0_data);
                g0_reg = (pwm_counter<g0_data);
                b0_reg = (pwm_counter<b0_data);
                r1_reg = (pwm_counter<r1_data);
                g1_reg = (pwm_counter<g1_data);
                b1_reg = (pwm_counter<b1_data);
                rgb <= {r0_reg, g0_reg, b0_reg, r1_reg, g1_reg, b1_reg};
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