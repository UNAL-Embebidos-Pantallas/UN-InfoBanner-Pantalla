module ram#(parameter IMAGEN="image.mem")(
    input wire i_clk,
    input wire request,
    output reg [23:0] o_valor,
    input [11:0]addrRead
);



    reg [23:0] ext_mem [2304:0];

    initial begin
        $readmemb(IMAGEN,ext_mem);
    end

always @(posedge i_clk)
begin
	if (request)	
	o_valor <= ext_mem[addrRead];
end


    /*always @ (posedge clk_req) begin
        o_valor <= ext_mem[counter];
        if (counter == 3200) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end*/
    
endmodule