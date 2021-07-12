module weightMemory(
	input clk,
	input reset,
	input READ,
	input WRITE,
	input [3:0] weight,
	input [4:0] Xloc,
	input [4:0] Yloc,
	input [4:0] XlocOUT,
	input [4:0] YlocOUT,
	output reg [26:0] dataOUT
);

	localparam brdHeight = 19;
	localparam brdWidth  = 19;

	localparam W1 = 0;
	localparam W2 = 1;
	localparam W3 = 2;
	localparam W4 = 3;
	localparam W5 = 4;
	localparam t1 = 5;
	localparam t2 = 6;
	localparam t3 = 7;
	localparam T =  8;

	reg [4:0] i,j;
	reg [4:0] x,y;
	reg [26:0] memory[0:(brdHeight-1)][0:(brdWidth-1)];
	
	initial begin
		for(i = 0; i < brdHeight; i = i + 1'b1)begin
			for(j = 0; j < brdHeight; j = j + 1'b1)begin
				memory[i][j] <= 27'd0;
			end
		end
		dataOUT <= 0;
	end
	
	always @ (posedge clk or posedge reset) begin
		if(reset)begin
			for(x = 0; x < brdHeight; x = x + 1'b1)begin
				for(y = 0; y < brdHeight; y = y + 1'b1)begin
					memory[x][y] <= 27'd0;
				end
			end
			dataOUT <= 0;
		end
		else begin
			if(WRITE)begin
				case(weight)
					W1: memory[Yloc][Xloc][(W1+2'd2):W1] = memory[Yloc][Xloc][(W1+2'd2):W1] + 1'b1;
					W2: memory[Yloc][Xloc][(2'd3*W2+2'd2):2'd3*W2] = memory[Yloc][Xloc][(2'd3*W2+2'd2):2'd3*W2] + 1'b1;
					W3: memory[Yloc][Xloc][(2'd3*W3+2'd2):2'd3*W3] = memory[Yloc][Xloc][(2'd3*W3+2'd2):2'd3*W3] + 1'b1;
					W4: memory[Yloc][Xloc][(2'd3*W4+2'd2):2'd3*W4] = memory[Yloc][Xloc][(2'd3*W4+2'd2):2'd3*W4] + 1'b1;
					W5: memory[Yloc][Xloc][(2'd3*W5+2'd2):2'd3*W5] = memory[Yloc][Xloc][(2'd3*W5+2'd2):2'd3*W5] + 1'b1;
					t1: memory[Yloc][Xloc][(2'd3*t1+2'd2):2'd3*t1] = memory[Yloc][Xloc][(2'd3*t1+2'd2):2'd3*t1] + 1'b1;
					t2: memory[Yloc][Xloc][(2'd3*t2+2'd2):2'd3*t2] = memory[Yloc][Xloc][(2'd3*t2+2'd2):2'd3*t2] + 1'b1;
					t3: memory[Yloc][Xloc][(2'd3*t3+2'd2):2'd3*t3] = memory[Yloc][Xloc][(2'd3*t3+2'd2):2'd3*t3] + 1'b1;
					T : memory[Yloc][Xloc][(2'd3*T+2'd2):2'd3*T] = memory[Yloc][Xloc][(2'd3*T+2'd2):2'd3*T] + 1'b1;
				endcase
			end
			else if(READ)begin
				dataOUT <= memory[YlocOUT][XlocOUT];
			end
		end
	end
	
endmodule 