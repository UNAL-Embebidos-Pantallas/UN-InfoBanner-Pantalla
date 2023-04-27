module led_matrix_control
  #(parameter MATRIX_COLS = 96,
    parameter MATRIX_ROWS = 48,
    parameter PWM_BITS = 4
  )
   (input i_clk,
    input rst,
    input [(3*PWM_BITS)-1:0] i_pixel_data1, // New input for pixel1 data
    input [(3*PWM_BITS)-1:0] i_pixel_data2, // New input for pixel2 data
    output reg [$clog2(MATRIX_COLS*MATRIX_ROWS)-1:0] o_pixel_addr,
    output reg o_clk,
    output reg o_oe,
    output reg o_latch,
    output reg [$clog2(MATRIX_ROWS/2)-1:0] o_row_sel,
    output [2:0] o_color1,
    output [2:0] o_color2
  );
    wire [$clog2(MATRIX_ROWS/2)-1:0] o_row_sel_next = o_row_sel + 1;

    reg [$clog2(MATRIX_COLS):0] pixel_counter;
    reg [PWM_BITS-1:0] pwm_counter;

    reg first_cycle;

    reg [(3*PWM_BITS)-1:0] pixel_1;
    reg [(3*PWM_BITS)-1:0] pixel_2;

    assign o_color1 = color(pixel_1);
    assign o_color2 = color(pixel_2);

    function [2:0] color (input reg [(3*PWM_BITS)-1:0] pixel);
        color = {
            (pwm_counter < pixel[PWM_BITS-1:0]),
            (pwm_counter < pixel[(2*PWM_BITS)-1:PWM_BITS]),
            (pwm_counter < pixel[(3*PWM_BITS)-1:2*PWM_BITS])
        };
    endfunction

    reg [2:0] state;

    localparam STATE_DISPLAY_1  = 3'b000;
    localparam STATE_DISPLAY_2  = 3'b001;
    localparam STATE_BLANK_1    = 3'b010;
    localparam STATE_BLANK_2    = 3'b011;
    localparam STATE_BLANK_3    = 3'b100;

    always @(posedge i_clk)
    begin
        if(rst)
            begin
                o_clk         <= 0;
                o_oe          <= 0;
                o_latch       <= 0;
                o_row_sel     <= ~0;
                o_pixel_addr  <= 0;
                
                pixel_1       <= 0;
                pixel_2       <= 0;
                temp_pixel    <= 0;
                
                pixel_counter <= 0;
                pwm_counter   <= 0;
                first_cycle   <= 1;
                
                state <= STATE_DISPLAY_2;
            end
        else
            begin
                case(state)
                    STATE_DISPLAY_1:
                    begin
                        o_oe <= 0;
                        o_latch <= 0;
                        o_clk <= !first_cycle;

                        temp_pixel <= i_pixel_data;

                        if(pixel_counter > MATRIX_COLS)
                        begin
                            state <= STATE_BLANK_1;
                        end
                        else
                        begin
                            o_pixel_addr <= pixel_counter + MATRIX_COLS*o_row_sel_next;
                            state <= STATE_DISPLAY_2;
                        end
                    end
                    STATE_DISPLAY_2:
                    begin
                        o_clk <= 0;
                        first_cycle <= 0;

                        if(!first_cycle)
                        begin
                            pixel_1 <= temp_pixel;
                            pixel_2 <= i_pixel_data;
                        end

                        o_pixel_addr <= pixel_counter + MATRIX_COLS*(MATRIX_ROWS/2 + o_row_sel_next);
                        pixel_counter <= pixel_counter + 1;

                        state <= STATE_DISPLAY_1;
                    end
                    STATE_BLANK_1:
                    begin
                        if(o_pixel_addr != 0)
                        begin
                            pixel_1 <= temp_pixel;
                            pixel_2 <= i_pixel_data;
                        end
                        else
                        begin
                            pixel_1 <= i_pixel_data;
                            pixel_2 <= temp_pixel;
                        end

                        o_clk <= 0;
                        pixel_counter[$clog2(MATRIX_COLS)] = 0;
                        state <= STATE_BLANK_2;
                    end
                    STATE_BLANK_2:
                    begin
                        o_oe <= 1;
                        state <= STATE_BLANK_3;
                    end
                    STATE_BLANK_3:
                    begin
                        o_row_sel <= o_row_sel + 1;
                        o_latch <= 1;
                        first_cycle <= 1;

                        if(o_row_sel == (MATRIX_ROWS/2)-2)
                        begin
                            pwm_counter <= pwm_counter + 1;
                        end

                        state <= STATE_DISPLAY_1;
                    end
                endcase
            end
    end
endmodule