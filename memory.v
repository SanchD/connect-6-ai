`define brdHeight 19
`define brdWidth  19
`define noMemLoc  brdHeight*brdWidth

module memory
	(
		input clk,
		input reset,
		input enaRead,
		input enaWrite,
		input [4:0] Xloc,
		input [4:0] Yloc,
		input [4:0] rawHrzntl,
		input [4:0] columnVrtcl,
		input [4:0] DiagonalNW,
		input [4:0] DiagonalNE,
		input [1:0] dataWrite,
		output reg [1:0] dataReadHrzntl[0:18],
		output reg [1:0] dataReadVrtcl[0:18],
		output reg [1:0] dataReadDiaNW[0:18],
		output reg [1:0] dataReadDiaNE[0:18]
	);
	
	reg [1:0] memArray[0:18][0:18];
	reg [4:0] x;
	reg [4:0] y;
	reg [1:0] temp [0:18];
	
	always @ (posedge clk or posedge reset)	begin
		if(reset) begin
			memArray <= 0;
			data <= 0;
		end
		
		else begin
			if(enaRead)	begin
				dataReadHrzntl <= memArray[rawHrzntl][0:18];
				for(x = 0; x < brdHeight; x = x + 1)begin
					temp[x] = memArray[x][columnVrtcl];
				end
				dataReadVrtcl  <= temp; 
				if(DiagonalNW < 19)begin
					for(x = 0; x <= DiagonalNW; x = x + 1)begin					
						temp[x] = memArray[18-DiagonalNW+x][x];					
					end
				end
				else begin
					for(x = (DiagonalNW-19+1); x <= (19-1); x = x + 1)begin					
						temp[x] = memArray[x-1][x];					
					end					
				end
				dataReadDiaNW  <= temp;
				if(DiagonalNE < 19)begin
					for(y = 0; y <= DiagonalNE; y = y + 1)begin					
						temp[y] = memArray[y][19-DiagonalNE+y];					
					end
				end
				else begin
					for(y = (DiagonalNE-19+1); y <= (19-1); y = y + 1)begin					
						temp[y] = memArray[y][y-1];					
					end	
				end
				dataReadDiaNE  <= temp;				
			end
			else if(enaWrite) begin
				memArray[Xloc][Yloc] <= dataWrite;
			end
		end
	end
endmodule 