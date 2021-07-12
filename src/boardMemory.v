module boardMemory(
	input clk,
	input reset,
	input READ,
	input WRITE,
	input [4:0] Xloc,
	input [4:0] Yloc,
	input [1:0] dataIN,
	input [4:0] XlocV,
	input [4:0] YlocV,
	input [4:0] XlocH,
	input [4:0] YlocH,
	input [4:0] XlocNE,
	input [4:0] YlocNE,
	input [4:0] XlocNW,
	input [4:0] YlocNW,
	output reg [1:0] verticleDataOUT,
	output reg [1:0] horizontalDataOUT,
	output reg [1:0] NEDataOUT,
	output reg [1:0] NWDataOUT
	);
	
	localparam brdHeight = 19;
	localparam brdWidth  = 19;
	
	reg [4:0] i,j;
	reg [1:0] memArray[0:brdHeight-1][0:brdWidth-1];
	
	initial begin
		for(i = 0; i < brdHeight; i = i + 1'b1)begin
			for(j = 0; j < brdHeight; j = j + 1'b1)begin
				memArray[i][j] <= 2'd0;
			end
		end
		verticleDataOUT <= 2'd0;
		horizontalDataOUT <= 2'd0;
		NEDataOUT <= 2'd0;
		NWDataOUT <= 2'd0;					
	end
	
	always @ (posedge clk or posedge reset) begin
		if(reset)begin
			for(i = 0; i < brdHeight; i = i + 1'b1)begin
				for(j = 0; j < brdHeight; j = j + 1'b1)begin
					memArray[i][j] <= 2'd0;
				end
			end
			verticleDataOUT <= 2'd0;
			horizontalDataOUT <= 2'd0;
			NEDataOUT <= 2'd0;
			NWDataOUT <= 2'd0;			
		end
		else begin
			if(READ) begin
				verticleDataOUT <= memArray[YlocV][XlocV];
				horizontalDataOUT <= memArray[YlocH][XlocH];
				NEDataOUT <= memArray[YlocNE][XlocNE];
				NWDataOUT <= memArray[YlocNW][XlocNW];
			end
			else if(WRITE) begin 
				memArray[Yloc][Xloc] <= dataIN;
			end
		end 
	end
endmodule 