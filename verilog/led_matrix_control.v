module led_matrix_control
(
    input wire clk_25MHz,
    output wire [4:0] row_addr,
    output wire blank,
    output wire latch,
    output wire next_line_begin,
    input wire next_line_done,
    output wire [4:0] next_line_addr,
    output wire [3:0] next_line_pwm,
    output wire base_addr,
    output wire ram_en,
);

reg blank = 1'b1;
reg latch = 1'b0;

reg [4:0] row_counter = 0;
reg [3:0] pwm_counter = 0;
reg base_addr_reg = 1;
assign row_addr = row_counter;
assign next_line_pwm = pwm_cousnter;
assign next_line_addr = row_addr;
assign base_addr = base_addr_reg;

reg next_line_begin;

parameter S_DEFAULT = 0;
parameter S_AFTER_FIRST_LINE_BEGIN = 1;
parameter S_DATA_SHIFT = 2;
parameter S_BLANK_SET = 3;
parameter S_LATCH_SET = 4;
parameter S_INCRE_ROW = 5;
parameter S_LATCH_CLR = 6;
parameter S_UNBLANK = 7;

reg [2:0] state = S_DEFAULT;

always @(posedge clk_25MHz) begin
    case (state)
        S_DEFAULT : begin
            next_line_begin <= 1;
            state <= S_AFTER_FIRST_LINE_BEGIN;
        end

        S_AFTER_FIRST_LINE_BEGIN : begin
            next_line_begin <= 0;
            state <= S_DATA_SHIFT;
        end

        // Main loop

        S_DATA_SHIFT : begin
            ram_en <= 1;
            if (next_line_done)begin
                state <= S_BLANK_SET;
            end   
        end

        S_BLANK_SET : begin
            ram_en <= 0;
            blank <= 1;
            state <= S_LATCH_SET;
        end

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

        S_LATCH_CLR : begin
            latch <= 0;
            next_line_begin <= 1;
            state <= S_UNBLANK;
        end

        S_UNBLANK : begin
            blank <= 0;
            next_line_begin <= 0;
            if (row_counter == 23) begin
                base_addr_reg <= 0;
                if (pwm_counter == 3)
                        // If we hit the lsb, wrap to the msb
                    pwm_counter <= 0;
                else
                    pwm_counter <= pwm_counter + 1;
            end
            else
                base_addr_reg <= 1;
            state <= S_DATA_SHIFT;
        end
    endcase
end
endmodule