`default_nettype none

module led_matrix_control(
    input wire clk,
    // Memory interface
    output wire [11:0] addr_out,
    input wire [15:0] data_in_rgb0,
    input wire [15:0] data_in_rgb1,
    output wire rd_en,
    // Shift register control
    output wire sclk,
    output wire latch,
    output wire OE,
    // Shift register data
    output wire [1:0] r_data,
    output wire [1:0] g_data,
    output wire [1:0] b_data,
    // Row select
    output wire [4:0] row_sel
);

parameter PRESCALER = 0;

localparam DATA_SHIFT = 0, OE_SET = 1, LAT_SET = 2, INCRE_ROW = 3,
LAT_CLR = 4, OE_CLR = 5;

// Register RAM signals
reg [10:0] addr_reg = 0;
reg rd_en_reg = 0;
assign addr_out = addr_reg;
assign rd_en = rd_en_reg;

// Register some outputs
reg sclk_reg = 0;
reg latch_reg = 0;
reg OE_reg = 1;
reg [4:0] row_address = ~5'b0;
reg [1:0] r_reg = 0;
reg [1:0] g_reg = 0;
reg [1:0] b_reg = 0;

// Wire up outputs
assign sclk = sclk_reg;
assign latch = latch_reg;
assign OE = OE_reg;
assign row_sel = row_address;
assign r_data = r_reg;
assign g_data = g_reg;
assign b_data = b_reg;

// Since the panel might not be able to run at core clock speed,
// add a prescaler to panel operations
reg [$clog2(PRESCALER):0] prescaler_reg = 0;

// In order to do better than 8 colours (R,G,B or combinations thereof)
// we need to do some more complex multiplexing of the panel than just
// scanning it once per update cycle. Instead, we want to display the
// most significant bit of each colour twice as long as the next most
// significant bit.
// If we pack the image data about as densely as wel can, using the
// RGB565 format (5 bits red, 6 bits green, five bits blue) we have
// five bits of information for each colour. To dispalay each one twice
// as long as the previous, we need the following number of time periods
// per bit of information:
// Bit 0: 1  (LSB)
// Bit 1: 2
// Bit 2: 4
// Bit 3: 8
// Bit 4: 16 (MSB).
// In total, that's 31 time periods per update cycle if we want to display
// colours with a 5 bit depth.

// How many periods should we wait for the given bit of the pixel data
// Bit 4 = MSB
reg [8:0] time_periods_for_bit[5];
initial begin
    time_periods_for_bit[4] = 128;
    time_periods_for_bit[3] = 64;
    time_periods_for_bit[2] = 32;
    time_periods_for_bit[1] = 16;
    time_periods_for_bit[0] = 8;
end

// How many time periods should we continue to wait for this bit of the
// pixel data
reg [8:0] time_periods_remaining;

// Which bit of the pixel data are we currently displaying
reg [2:0] pixel_bit_index = 4;
reg [2:0] state = DATA_SHIFT;
reg [7:0] pixels_to_shift = 48;

// Next state logic
always @(state, row_address, pixel_bit_index, pixels_to_shift) begin
    case(state)
        DATA_SHIFT:
            if(pixels_to_shift <= 0)
                state <= OE_SET;
        OE_SET: state <= LAT_SET;
        LAT_SET: state <= INCRE_ROW;
        INCRE_ROW: state <= LAT_CLR;
        LAT_CLR: state <= OE_CLR;
        OE_CLR:
            if(row_address == 0)
                if(pixel_bit_index == 0)
                    state <= DATA_SHIFT;
                else
                    state <= OE_SET;
            else
                state <= DATA_SHIFT;
    endcase
end

// Output logic
always @(state, row_address, pixel_bit_index, pixels_to_shift, sclk_reg) begin
    case(state)
        DATA_SHIFT:
            begin
                if(time_periods_remaining == 0)
                    OE_reg <= 1;
                else
                    time_periods_remaining <= time_periods_remaining - 1;
                    
                if(pixels_to_shift > 0)
                    begin
                        if(sclk_reg == 0)
                            begin
                                r_reg <= {data_in_rgb1[11 + pixel_bit_index],
                                           data_in_rgb0[11 + pixel_bit_index]};
                                g_reg <= {data_in_rgb1[6 + pixel_bit_index],
                                           data_in_rgb0[6 + pixel_bit_index]};
                                b_reg <= {data_in_rgb1[0 + pixel_bit_index],
                                           data_in_rgb0[0 + pixel_bit_index]};
                                sclk_reg <= 1;
                                addr_reg <= addr_reg + 1;
                            end
                        else
                            begin
                                sclk_reg <= 0;
                                pixels_to_shift <= pixels_to_shift - 1;
                            end
                    end
            end
        OE_SET: OE_reg <= 1;
        LAT_SET: latch_reg <= 1;
        INCRE_ROW: row_address <= row_address + 1;
        LAT_CLR: latch_reg <= 0;
        OE_CLR:
            begin
                OE_reg <= 0;
                time_periods_remaining <= time_periods_for_bit[pixel_bit_index];
                pixels_to_shift <= 64;
                rd_en_reg <= 1;
                if(row_address == 0)
                    if(pixel_bit_index == 0)
                        pixel_bit_index <= 4;
                    else
                        pixel_bit_index <= pixel_bit_index - 1;
            end
    endcase
end

// Transition state logic
always @(posedge clk) begin
    if(prescaler_reg > 0)
        prescaler_reg <= prescaler_reg - 1;
    else
        prescaler_reg <= PRESCALER[$clog2(PRESCALER):0];
    case(state)
        DATA_SHIFT:
            begin
                if(pixels_to_shift > 0)
                    rd_en_reg <= 1;
                else
                    rd_en_reg <= 0;
            end
        OE_SET:;
        LAT_SET:;
        INCRE_ROW:;
        LAT_CLR:;
        OE_CLR:;
    endcase
end

endmodule