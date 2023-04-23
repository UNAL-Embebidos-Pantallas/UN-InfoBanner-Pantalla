module led_matrix_control(
	input clk,
	input rst,
	output reg CE,
	output reg clk_en,
	output reg LAT,
	output reg OE,
	output reg busy,
	output reg [3:0] row_addr
);
	
parameter INIT = 4'd0, PRE = 4'd1, DATA = 4'd2, POST = 4'd3, 
LATCH = 4'd4, OUTPUT = 4'd5, DEAD = 4'd6, INC = 4'd7, DEADinc = 4'd8;
	
reg [31:0] cycle_count;
reg [3:0] state;
reg [3:0] next_state;
//Next State Logic
always @ (*) begin
case(state)
	INIT:   next_state = PRE;
	PRE:    next_state = (cycle_count == 1) ? DATA : PRE;
	DATA:   next_state = (cycle_count == 29) ? POST : DATA;
	POST:   next_state = (cycle_count == 1) ? LATCH : POST;
	LATCH:  next_state = OUTPUT;
	OUTPUT: next_state = (cycle_count == 15000) ? DEAD : OUTPUT;
	DEAD:   next_state = (cycle_count == 250) ? INC : DEAD;
	INC:    next_state = DEADinc;
	DEADinc:next_state = (cycle_count == 250) ? PRE : DEADinc;
	default: next_state = INIT;
endcase
end
	
//Output Logic
always @ (state) begin
	case(state)
	INIT:   begin CE = 1'b0; clk_en = 1'b0; LAT = 1'b0; OE = 1'b1; busy = 0; end
	PRE:    begin CE = 1'b1; clk_en = 1'b0; LAT = 1'b0; OE = 1'b1; busy = 1; end
	DATA:   begin CE = 1'b1; clk_en = 1'b1; LAT = 1'b0; OE = 1'b1; busy = 1; end
	POST:   begin CE = 1'b0; clk_en = 1'b1; LAT = 1'b0; OE = 1'b1; busy = 1; end
	LATCH:  begin CE = 1'b0; clk_en = 1'b0; LAT = 1'b1; OE = 1'b1; busy = 0; end
	OUTPUT: begin CE = 1'b0; clk_en = 1'b0; LAT = 1'b0; OE = 1'b0; busy = 0; end
	DEAD:   begin CE = 1'b0; clk_en = 1'b0; LAT = 1'b0; OE = 1'b1; busy = 0; end
	INC:    begin CE = 1'b0; clk_en = 1'b0; LAT = 1'b0; OE = 1'b1; busy = 0; end
	DEADinc:begin CE = 1'b0; clk_en = 1'b0; LAT = 1'b0; OE = 1'b1; busy = 0; end
	default:begin CE = 1'b0; clk_en = 1'b0; LAT = 1'b0; OE = 1'b1; busy = 0; end
endcase	
end
	
//State Transition Logic
always @ (posedge clk, posedge rst) begin
	if(rst) begin
		state <= INIT;
		cycle_count <= 0;
	end
	else if(next_state != state) begin
		state <= next_state;
		cycle_count <= 0;
	end
	else begin 
		state <= next_state;
		cycle_count <= cycle_count + 1; 
	end
end
	
//Row Address Logic
always @ (posedge clk, posedge rst) begin
	if(rst) begin
		row_addr <= 0;
	end
	else if(state == INC) begin
		row_addr <= row_addr + 1;
	end
	else begin 
		row_addr <= row_addr;
	end
end
endmodule