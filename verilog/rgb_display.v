`include "led_matrix_control.v"
module rgb_display (
    // Input clock to our panel driver
    input wire i_clk,
    input wire i_rst,
    // Shift register controls for the column data
    output reg o_data_clock,
    output reg o_data_latch,
    output reg o_data_blank,
    // Data lines to be shifted
    output reg r0, g0, b0, r1, g1, b1,
    // Inputs to the row select demux
    output reg [4:0] o_row_select,
    // Blink led
);

    reg [1:0] count;
    reg clk_25MHz;

    always @(posedge i_clk) begin
    count <= count + 1;
    if (count == 2) begin
        count <= 0;
        clk_25MHz <= ~clk_25MHz;
    end
    end

    // How many pixels to shift per row
    localparam pixels_per_row = 48;

    // State machine IDs
    localparam
        s_data_shift = 0,
        s_blank_set = 1,
        s_latch_set = 2,
        s_increment_row = 3,
        s_latch_clear = 4,
        s_blank_clear = 5;

    reg [1:0] o_data_r;
    reg [1:0] o_data_g;
    reg [1:0] o_data_b;

    reg [1:0] data_r = 0;
    reg [1:0] data_g = 0;
    reg [1:0] data_b = 0;

    // Wire up outputs
    assign o_data_r = data_r;
    assign o_data_g = data_g;
    assign o_data_b = data_b;

    // Wire RGB0-RGB1
    assign r0 = o_data_r[0];
    assign g0 = o_data_g[0];
    assign b0 = o_data_b[0];
    assign r1 = o_data_r[1];
    assign g1 = o_data_g[1];
    assign b1 = o_data_b[1];

    // Simple colour cycling logic. We will have a prescaler that counts down
    // to zero twice per second, based on the frequency of our module input
    // clock (`CLOCK_HZ`).
    // Whenever this countdown hits zero, we will increment our colour state
    // register, each bit of which is mapped to the reg, green or blue data
    // channel of the RGB panel shift registers.
    localparam COLOUR_CYCLE_PRESCALER = (25000000 / 2) - 1;
    reg [$clog2(COLOUR_CYCLE_PRESCALER):0] colour_cycle_counter = 0;
    reg [2:0] colour_register;

    always @(posedge clk_25MHz) begin
        if (colour_cycle_counter == 0) begin
            colour_register <= colour_register + 1;
            colour_cycle_counter <= COLOUR_CYCLE_PRESCALER;
        end else
            colour_cycle_counter <= colour_cycle_counter - 1;
            counterk <= counterk + 1;
    end

    // Connect the output colour data lines to our colour counter
    /*assign o_data_r = {colour_register[0], colour_register[0]};
    assign o_data_g = {colour_register[1], colour_register[1]};
    assign o_data_b = {colour_register[2], colour_register[2]};*/

    // El bit de más peso es el más a la derecha.
    reg [4:0] red_register   = {1'b1, 1'b1, 1'b1, 1'b0, 1'b1};
    reg [4:0] green_register = {1'b1, 1'b0, 1'b0, 1'b0, 1'b0};
    reg [4:0] blue_register  = {1'b1, 1'b0, 1'b0, 1'b0, 1'b0};

    /*reg [3:0] counterk;
    assign o_data_r = {colour_register[0], red_register[counterk]};
    assign o_data_g = {colour_register[1], green_register[counterk]};
    assign o_data_b = {colour_register[2], blue_register[counterk]};*/
 
    // Time periods for each color bit
    reg [8:0] time_periods_x_bit[5]; 
    initial begin
        time_periods_x_bit[4] = 96; // 2*80 pixels
        time_periods_x_bit[3] = 48;
        time_periods_x_bit[2] = 24;
        time_periods_x_bit[1] = 12;
        time_periods_x_bit[0] = 6;
    end

    reg [8:0] time_periods_remaining; // 512 > 160+80+40+20+10 = 310
    reg [2:0] counter = 4;

    // Register to keep track of where we are in our panel update state machine
    reg [2:0] state = s_data_shift;
    // How many pixels remain to be shifted in the 'data_shift' state
    reg [7:0] pixels_to_shift;
    always @(posedge clk_25MHz) begin
        case (state)
        s_data_shift: begin // Shift out new column data for this row
            // Se va restando los periodos restantes para cada bit de color
            if (time_periods_remaining == 0) begin
                o_data_blank <= 0;
            end else begin
                time_periods_remaining <= time_periods_remaining - 1;
            end
            // 
            if (pixels_to_shift > 0) begin
                // We have data to shift still
                if (o_data_clock == 1) begin
                    // For this test, we have hardcoded our colour output, so
                    // there is nothing to do per-pixel here
                    data_r <= {colour_register[0], red_register[counter]};
                    data_g <= {colour_register[1], green_register[counter]};
                    data_b <= {colour_register[2], blue_register[counter]};
                    o_data_clock <= 0;
                end else begin
                    o_data_clock <= 1;
                    pixels_to_shift <= pixels_to_shift - 1;
                end
            end else
               state <= s_blank_set;
         end
         // In order to update the column data, these shift registers actually
         // seem to require the output is disabled before they will latch new
         // data. So to perform an update, we have a series of steps here that
         // - Blank the output
         // - Latch the new data
         // - Increment to the new row address
         // - Reset the latch state
         // - Unblank the display.
         // Each step has been made it's own state for clarity; if one wanted
         // to save a little more on logic some of these steps can be merged.
         s_blank_set: begin o_data_blank <= 1; state <= s_latch_set; end
         s_latch_set: begin o_data_latch <= 1; state <= s_increment_row; end
         s_increment_row: begin o_row_select <= o_row_select + 1;
                                state <= s_latch_clear; end
         s_latch_clear: begin o_data_latch <= 0; state <= s_blank_clear; end
         s_blank_clear: begin
             o_data_blank <= 0;
             pixels_to_shift <= pixels_per_row;
             // Dependiendo del bit de color en el que este se cambia el tiempo de encendido.
             time_periods_remaining <= time_periods_x_bit[counter];
             // Cuando o_row_select es cero, se hizo una escaneada de bit de color y se pasa al siguente LSB
             if (o_row_select == 0) begin
                if (counter == 0)
                    // If we hit the lsb, wrap to the msb
                    counter <= 4;
                else
                    counter <= counter - 1;
             end
             state <= s_data_shift;
         end
        endcase
    end
endmodule