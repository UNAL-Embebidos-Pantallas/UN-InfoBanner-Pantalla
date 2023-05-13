module led_matrix_control
  #()(
    // Input clock to our panel driver
    input wire i_clk,
    input wire i_rst,
    // Memory interface
    output wire [11:0] o_ram_addr,
    input wire [11:0] i_ram_b1_data,
    input wire [11:0] i_ram_b2_data,
    output wire o_ram_read_stb,

    // Shift register controls for the column data
    output reg o_data_clock,
    output reg o_data_latch,
    output reg o_data_blank,
    // Data lines to be shifted
    output reg [1:0] o_data_r,
    output reg [1:0] o_data_g,
    output reg [1:0] o_data_b,
    // Inputs to the row select demux
    output reg [4:0] o_row_select,
    // Blink led
  );
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

    reg [1:0] data_r = 0;
    reg [1:0] data_g = 0;
    reg [1:0] data_b = 0;

    // Wire up outputs
    assign o_data_r = data_r;
    assign o_data_g = data_g;
    assign o_data_b = data_b;

    reg [11:0] ram_addr = 0;
    reg ram_read_stb = 0;
    assign o_ram_addr = ram_addr;
    assign o_ram_read_stb = ram_read_stb;

    // Simple colour cycling logic. We will have a prescaler that counts down
    // to zero twice per second, based on the frequency of our module input
    // clock (`CLOCK_HZ`).
    // Whenever this countdown hits zero, we will increment our colour state
    // register, each bit of which is mapped to the reg, green or blue data
    // channel of the RGB panel shift registers.
    localparam COLOUR_CYCLE_PRESCALER = (25000000 / 2) - 1;
    reg [$clog2(COLOUR_CYCLE_PRESCALER):0] colour_cycle_counter = 0;
    reg [2:0] colour_register;

    always @(posedge i_clk) begin
        if (colour_cycle_counter == 0) begin
            colour_register <= colour_register + 1;
            colour_cycle_counter <= COLOUR_CYCLE_PRESCALER;
        end else
            colour_cycle_counter <= colour_cycle_counter - 1;
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
    reg [8:0] time_periods_x_bit[4]; 
    initial begin
        time_periods_x_bit[3] = 96; // 2*80 pixels
        time_periods_x_bit[2] = 48;
        time_periods_x_bit[1] = 24;
        time_periods_x_bit[0] = 12;
    end

    reg [7:0] time_periods_remaining; // 512 > 160+80+40+20+10 = 310
    reg [2:0] counter = 3;

    // Register to keep track of where we are in our panel update state machine
    reg [2:0] state = s_data_shift;
    // How many pixels remain to be shifted in the 'data_shift' state
    reg [7:0] pixels_to_shift;
    always @(posedge i_clk) begin
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
                if (o_data_clock == 0) begin
                    // For this test, we have hardcoded our colour output, so
                    // there is nothing to do per-pixel here
                    data_r <= {i_ram_b1_data[8+counter], i_ram_b2_data[8+counter]};
                    data_g <= {i_ram_b1_data[4+counter], i_ram_b2_data[4+counter]};
                    data_b <= {i_ram_b1_data[0+counter], i_ram_b2_data[0+counter]};
                    o_data_clock <= 1;
                    ram_addr <= ram_addr + 1;
                end else begin
                    o_data_clock <= 0;
                    pixels_to_shift <= pixels_to_shift - 1;
                end
            end else
               ram_read_stb <= 0;
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
             ram_read_stb <= 1;
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