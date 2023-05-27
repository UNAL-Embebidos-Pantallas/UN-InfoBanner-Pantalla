module led_matrix_control
  #()(
    // Input clock to our panel driver
    // Input clock to our panel driver
    input wire i_clk,
    input wire i_rst,
    // // Blink buttom
    // input enable,
    // Shift register controls for the column data
    output reg [11:0] o_ram_addr,
    input wire[23:0] i_ram_data,
    output reg o_ram_read_stb,
    output reg o_data_clock,
    output reg o_data_latch,
    output reg o_data_blank,
    // Data lines to be shifted
    output reg [1:0] o_data_r,
    output reg [1:0] o_data_g,
    output reg [1:0] o_data_b,
    // Inputs to the row select demux
    output reg [4:0] o_row_select,
);
    wire [23:0] data;
    reg enable_ram;
    reg [11:0]addrRead;
    assign o_ram_addr = addrRead;
    assign i_ram_data = data;
    assign o_ram_read_stb = enable_ram;
    
   /* Decoder_3to7 decodeR0(.input_data(data[35:33]),.output_data(red_register));
    Decoder_3to7 decodeG0(.input_data(data[32:30]),.output_data(green_register));
    Decoder_3to7 decodeB0(.input_data(data[29:27]),.output_data(blue_register));*/
    // How many pixels to shift per row
    localparam pixels_per_row = 96;

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

    // Simple colour cycling logic. We will have a prescaler that counts down
    // to zero twice per second, based on the frequency of our module input
    // clock (`CLOCK_HZ`).
    // Whenever this countdown hits zero, we will increment our colour state
    // register, each bit of which is mapped to the reg, green or blue data
    // channel of the RGB panel shift registers.
   
    // Blink 
    // always @(posedge i_clk) begin
    //     if (enable)
    //         led <= 1'b1;
    //     else 
    //         led <= 1'b0;
    // end

    
    // Connect the output colour data lines to our colour counter
    /*assign o_data_r = {colour_register[0], colour_register[0]};
    assign o_data_g = {colour_register[1], colour_register[1]};
    assign o_data_b = {colour_register[2], colour_register[2]};*/

    // El bit de más peso es el más a la derecha.
    
    /*reg [6:0] red_register   = {1'b1, 1'b1, 1'b1, 1'b1, 1'b1 ,1'b0, 1'b0};
    reg [6:0] green_register = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0 ,1'b0, 1'b0};
    reg [6:0] blue_register  = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0 ,1'b0, 1'b0};
    reg [6:0] red_register2   = {1'b1, 1'b0, 1'b0, 1'b0, 1'b0 ,1'b0, 1'b0};
    reg [6:0] green_register2 = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0 ,1'b0, 1'b0};
    reg [6:0] blue_register2  = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0 ,1'b0, 1'b0};*/
    reg red_register   = 0;
    reg green_register = 0;
    reg blue_register  = 0;
    reg red_register2   = 0;
    reg green_register2 = 0;
    reg blue_register2  = 0;

    /*reg [3:0] counterk;
    assign o_data_r = {colour_register[0], red_register[counterk]};
    assign o_data_g = {colour_register[1], green_register[counterk]};
    assign o_data_b = {colour_register[2], blue_register[counterk]};*/
 
    // Time periods for each color bit
    /*reg [32:0] time_periods_x_bit[5]; 
    initial begin
        time_periods_x_bit[4] = 320000; // 2*80 pixels
        time_periods_x_bit[3] = 80;
        time_periods_x_bit[2] = 40;
        time_periods_x_bit[1] = 20;
        time_periods_x_bit[0] = 10;
    end*/

    reg [8:0] time_periods_remaining; // 512 > 160+80+40+20+10 = 310
    reg [3:0] counter = 1;
    reg C;
    // Register to keep track of where we are in our panel update state machine
    reg [2:0] state = s_data_shift;
    // How many pixels remain to be shifted in the 'data_shift' state
    reg [35:0] pixels_to_shift=0;
    reg [3:0] dataPixelR=6;
    reg [3:0] dataPixelG=2;
    reg [3:0] dataPixelB=4;

    reg [3:0] dataPixelR2=6;
    reg [3:0] dataPixelG2=2;
    reg [3:0] dataPixelB2=4;
    reg [30:0] count3;
    always @(posedge i_clk) begin
        case (state)
        s_data_shift: begin // Shift out new column data for this row
            // Se va restando los periodos restantes para cada bit de color
            /*if (time_periods_remaining == 0) begin
                o_data_blank <= 0;
            end else begin
                time_periods_remaining <= time_periods_remaining - 1;
            end*/
            // 
            enable_ram=1;
            addrRead=pixels_to_shift+96*o_row_select;
            dataPixelR=data[23:20];
            dataPixelG=data[19:16];
            dataPixelB=data[15:12];

            dataPixelR2=data[11:8];
            dataPixelG2=data[7:4];
            dataPixelB2=data[3:0];
            if (pixels_to_shift != pixels_per_row ) begin
                
                
                // We have data to shift still
                if (o_data_clock == 1) begin
                    // For this test, we have hardcoded our colour output, so
                    // there is nothing to do per-pixel here
                    //C = (pixels_to_shift==8'b00000100) ? 1'b1 : 1'b0;        
                    //data_r <= { red_register2[counter], red_register[counter]};
                    red_register    = (counter<=dataPixelR) ? 1'b1 : 1'b0; 
                    red_register2   = (counter<=dataPixelR2) ? 1'b1 : 1'b0; 
                    green_register  = (counter<=dataPixelG) ? 1'b1 : 1'b0; 
                    green_register2 = (counter<=dataPixelG2) ? 1'b1 : 1'b0; 
                    blue_register   = (counter<=dataPixelB) ? 1'b1 : 1'b0; 
                    blue_register2  = (counter<=dataPixelB2) ? 1'b1 : 1'b0; 
                
                    /*if(dataPixelG <=counter)
                        green_register=1;
                    else begin
                        green_register=0;
                    end
                    if(dataPixelB<=counter)
                        blue_register=1;
                    else begin
                        blue_register=0;
                    end*/
                    //C = (pixels_to_shift==8'b01001111) ? 1'b1 : 1'b0; 
                    data_r <= { red_register2, red_register}; 
                    data_g <= { green_register2, green_register}; 
                    data_b <= { blue_register2, blue_register}; 

                    o_data_clock <= 0;
                end else begin
                    o_data_clock <= 1;
                    pixels_to_shift <= pixels_to_shift + 1;
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
         s_blank_set: begin enable_ram = 0; o_data_blank <= 1; state <= s_latch_set; end
         s_latch_set: begin o_data_latch <= 1; state <= s_increment_row; end
         s_increment_row: begin 
            if(o_row_select==23)begin
                o_row_select<=0;
            end
            else begin
                o_row_select <= o_row_select + 1;
            end
            state <= s_latch_clear; 
            end
         s_latch_clear: begin 
            o_data_latch <= 0; 
            state <= s_blank_clear; 
            end
         s_blank_clear: begin
            o_data_blank <= 0;
            pixels_to_shift <= 0;
                // Dependiendo del bit de color en el que este se cambia el tiempo de encendido.
                //time_periods_remaining <= time_periods_x_bit[counter];
                // Cuando o_row_select es cero, se hizo una escaneada de bit de color y se pasa al siguente LSB
            if (o_row_select == 0) begin
                if (counter == 6)
                        // If we hit the lsb, wrap to the msb
                    counter <= 1;
                else
                    counter <= counter + 1;
            end
            /*if (count3==5000)
            begin
                state <= s_data_shift;
                count3<=0;
            end
            else begin
                count3<=count3+1;
            end*/
            state <= s_data_shift;
         end
        endcase
    end
endmodule