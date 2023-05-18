module led_matrix_control
(
    input wire clk_25MHz,
    output wire [4:0] row_addr,
    output wire blank,
    output wire latch,
    output wire next_line_begin,
    input wire next_line_done,
    output wire [4:0] next_line_addr,
    output wire [6:0] next_line_pwm,
);

reg blank = 1'b1;
reg latch = 1'b0;

reg [4:0] row_counter;
reg [6:0] pwm_counter;
assign row_addr = row_counter;
assign next_line_pwm = pwm_counter;
assign next_line_addr = row_addr;

reg next_line_begin;

parameter S_DEFAULT = 0;
parameter S_AFTER_FIRST_LINE_BEGIN = 1;
parameter S_DATA_SHIFT = 2;
parameter S_BLANK_SET = 3;
parameter S_LATCH_SET = 4;
parameter S_DEAD_TIME_SET = 5;
parameter S_INCRE_ROW = 6;
parameter S_LATCH_CLR = 7;
parameter S_UNBLANK = 8;
parameter S_DEAD_TIME_CLR = 9;

reg [31:0] dead_time_counter = 0; 
reg [3:0] state = S_DEFAULT;

always @(posedge clk_25MHz) begin
    case (state)
        S_DEFAULT : begin
            state <= S_AFTER_FIRST_LINE_BEGIN;
            next_line_begin <=1'b1;
        end

        S_AFTER_FIRST_LINE_BEGIN : begin
            next_line_begin <= 1'b0;
            state <= S_DATA_SHIFT;
        end

        // Main loop

        S_DATA_SHIFT : begin
            if (next_line_done)begin
                state <= S_BLANK_SET;
            end   
        end

        S_BLANK_SET : begin
            blank <= 1;
            state <= S_LATCH_SET;
        end

        //Dead time

        // S_DEAD_TIME_SET : begin
        //     if (dead_time_counter == 200) begin
        //         state <= S_LATCH_SET;
        //     end
        //     else
        //         state <= S_DEAD_TIME_SET;
        // end

        S_LATCH_SET : begin
            latch <= 1;           
            state <= S_INCRE_ROW;
        end

        S_INCRE_ROW : begin
            if(row_counter == 23)begin
                row_counter <= 0;
            end
            else begin
                row_counter <= row_counter + 1;
            end
            state <= S_LATCH_CLR;     
        end

        //Dead time

        // S_DEAD_TIME_CLR : begin
        //     if (dead_time_counter == 25) begin
        //         state <= S_LATCH_CLR;
        //     end
        //     else
        //         state <= S_DEAD_TIME_CLR;
        // end


        S_LATCH_CLR : begin
            latch <= 0;
            next_line_begin <= 1'b1;
            state <= S_UNBLANK;
        end

        S_UNBLANK : begin
            blank <= 0;
            next_line_begin <= 1'b0;
            state <= S_DATA_SHIFT;
        end
    endcase
end

// Dead time counter increment
always @(posedge clk_25MHz)
    begin
    if (state == S_DEAD_TIME_CLR || state == S_DEAD_TIME_SET)
    begin
        if (dead_time_counter != 200) // Check if counter has reached maximum value
        dead_time_counter <= dead_time_counter + 1;
    end
end

endmodule