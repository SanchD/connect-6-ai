module pointCal(
	input clk,
	input reset,
	input enaPointCal,
	input turn,
	input [26:0] dataINV,
	input [26:0] dataINH,
	input [26:0] dataINNE,
	input [26:0] dataINNW,
	output reg donePointCal,
	output reg READ,
	output reg [4:0] XlocV,
	output reg [4:0] YlocV,	
	output reg [4:0] XlocClick,
	output reg [4:0] YlocClick
	);
	
	localparam brdHeight = 19;
	localparam brdWidth  = 19;
	
	localparam STATE_START_CALC = 1;
	localparam STATE_TOTAL_WEIGHT = 2;
	localparam STATE_POINT_CLICK = 3;	
	localparam STATE_CALC_DONE = 3;	
	
	localparam SUBSTATE_READ_WWM = 1;
	localparam SUBSTATE_FETCH_WEIS = 2;
	localparam SUBSTATE_MAX_WEIT_LOCA = 3;
	localparam SUBSTATE_NEXT_CELL = 3;
	
	localparam W1 = 0;
	localparam W2 = 1;
	localparam W3 = 2;
	localparam W4 = 3;
	localparam W5 = 4;
	localparam t1 = 5;
	localparam t2 = 6;
	localparam t3 = 7;
	localparam T =  8;
	
	reg [2:0] mainState;
	reg [1:0] weightSubState;
	reg [4:0] i,j;
	reg [4:0] x;
	reg [4:0] y;
	reg [35:0] weightMemoryAll[0:(brdHeight-1)][0:(brdWidth-1)];
	
	reg [3:0] lastMaxW1;
	reg [3:0] lastMaxW2;
	reg [3:0] lastMaxW3;
	reg [3:0] lastMaxW4;
	reg [3:0] lastMaxW5;
	reg [3:0] lastMaxt1;
	reg [3:0] lastMaxt2;
	reg [3:0] lastMaxt3;
	reg [3:0] lastMaxT;
	
	reg [4:0] W1MaxXloc;
	reg [4:0] W1MaxYloc;
	reg [4:0] W2MaxXloc;
	reg [4:0] W2MaxYloc;
	reg [4:0] W3MaxXloc;
	reg [4:0] W3MaxYloc;
	reg [4:0] W4MaxXloc;
	reg [4:0] W4MaxYloc;
	reg [4:0] W5MaxXloc;
	reg [4:0] W5MaxYloc;
	reg [4:0] t1MaxXloc;
	reg [4:0] t1MaxYloc;
	reg [4:0] t2MaxXloc;
	reg [4:0] t2MaxYloc;
	reg [4:0] t3MaxXloc;
	reg [4:0] t3MaxYloc;
	reg [4:0] TMaxXloc;
	reg [4:0] TMaxYloc;
	
	initial begin
		for(i = 0; i < brdHeight; i = i + 1'b1)begin
			for(j = 0; j < brdHeight; j = j + 1'b1)begin
				weightMemoryAll[i][j] <= 35'd0;
			end
		end
		
		donePointCal <= 1'd0;
		XlocV <= 5'd0;
		YlocV <= 5'd0;
		XlocClick <= 5'd0;
		YlocClick <= 5'd0;	
		x <= 5'd0;
		y <= 5'd0;
		
		lastMaxW1 <= 4'b0;
		lastMaxW2 <= 4'b0;
		lastMaxW3 <= 4'b0;
		lastMaxW4 <= 4'b0;
		lastMaxW5 <= 4'b0;
		lastMaxt1 <= 4'b0;
		lastMaxt2 <= 4'b0;
		lastMaxt3 <= 4'b0;
		lastMaxT  <= 4'b0;
		
		mainState <= STATE_START_CALC;
	end
	
	always @ (posedge clk or posedge reset) begin
		if(reset)begin
			for(i = 0; i < brdHeight; i = i + 1'b1)begin
				for(j = 0; j < brdHeight; j = j + 1'b1)begin
					weightMemoryAll[i][j] <= 35'd0;
				end
			end
			
			donePointCal <= 1'd0;
			XlocV <= 5'd0;
			YlocV <= 5'd0;
			XlocClick <= 5'd0;
			YlocClick <= 5'd0;
			x <= 5'd0;
			y <= 5'd0;
			
			lastMaxW1 <= 4'b0;
			lastMaxW2 <= 4'b0;
			lastMaxW3 <= 4'b0;
			lastMaxW4 <= 4'b0;
			lastMaxW5 <= 4'b0;
			lastMaxt1 <= 4'b0;
			lastMaxt2 <= 4'b0;
			lastMaxt3 <= 4'b0;
			lastMaxT  <= 4'b0;
			
			mainState <= STATE_START_CALC;
		end 
		else begin
			case(mainState)
				STATE_START_CALC:begin
					if(enaPointCal)begin
						mainState <= STATE_TOTAL_WEIGHT;
						donePointCal <= 1'd0;
					end
				end
				STATE_TOTAL_WEIGHT:begin
					case(weightSubState)
						SUBSTATE_READ_WWM:begin
							READ <= 1'd1;
							XlocV <= x;
							YlocV <= y;
							weightSubState <= SUBSTATE_FETCH_WEIS;
						end
						SUBSTATE_FETCH_WEIS:begin
							weightMemoryAll[y][x][W1+3:W1] <= dataINV[(W1+2):W1] + dataINH[(W1+2):W1] + dataINNE[(W1+2):W1] + dataINNW[(W1+2):W1];
							weightMemoryAll[y][x][3*W2+3:3*W2] <= dataINV[(3*W2+2):3*W2] + dataINH[(3*W2+2):3*W2] + dataINNE[(3*W2+2):3*W2] + dataINNW[(3*W2+2):3*W2];
							weightMemoryAll[y][x][3*W3+3:3*W3] <= dataINV[(3*W3+2):3*W3] + dataINH[(3*W3+2):3*W3] + dataINNE[(3*W3+2):3*W3] + dataINNW[(3*W3+2):3*W3];
							weightMemoryAll[y][x][3*W4+3:3*W4] <= dataINV[(3*W4+2):3*W4] + dataINH[(3*W4+2):3*W4] + dataINNE[(3*W4+2):3*W4] + dataINNW[(3*W4+2):3*W4];
							weightMemoryAll[y][x][3*W5+3:3*W5] <= dataINV[(3*W5+2):3*W5] + dataINH[(3*W5+2):3*W5] + dataINNE[(3*W5+2):3*W5] + dataINNW[(3*W5+2):3*W5];
							weightMemoryAll[y][x][3*t1+3:3*t1] <= dataINV[(3*t1+2):3*t1] + dataINH[(3*t1+2):3*t1] + dataINNE[(3*t1+2):3*t1] + dataINNW[(3*t1+2):3*t1];
							weightMemoryAll[y][x][3*t2+3:3*t2] <= dataINV[(3*t2+2):3*t2] + dataINH[(3*t2+2):3*t2] + dataINNE[(3*t2+2):3*t2] + dataINNW[(3*t2+2):3*t2];
							weightMemoryAll[y][x][3*t3+3:3*t3] <= dataINV[(3*t3+2):3*t3] + dataINH[(3*t3+2):3*t3] + dataINNE[(3*t3+2):3*t3] + dataINNW[(3*t3+2):3*t3];
							weightMemoryAll[y][x][3*T+3:3*T] <= dataINV[(3*T+2):3*T] + dataINH[(3*T+2):3*T] + dataINNE[(3*T+2):3*T] + dataINNW[(3*T+2):3*T];
							weightSubState <= SUBSTATE_MAX_WEIT_LOCA;
						end
						SUBSTATE_MAX_WEIT_LOCA:begin
							if((weightMemoryAll[y][x][W1+3:W1] > 0)&&(weightMemoryAll[y][x][W1+3:W1] > lastMaxW1))begin
								lastMaxW1 <= weightMemoryAll[y][x][W1+3:W1];
								W1MaxXloc <= x;
								W1MaxYloc <= y;
							end	
							if((weightMemoryAll[y][x][3*W2+3:3*W2] > 0)&&(weightMemoryAll[y][x][3*W2+3:3*W2] > lastMaxW1))begin
								lastMaxW2 <= weightMemoryAll[y][x][3*W2+3:3*W2];
								W2MaxXloc <= x;
								W2MaxYloc <= y;
							end	
							if((weightMemoryAll[y][x][3*W3+3:3*W3] > 0)&&(weightMemoryAll[y][x][3*W3+3:3*W3] > lastMaxW1))begin
								lastMaxW3 <= weightMemoryAll[y][x][3*W3+3:3*W3];
								W3MaxXloc <= x;
								W3MaxYloc <= y;
							end	
							if((weightMemoryAll[y][x][3*W4+3:3*W4] > 0)&&(weightMemoryAll[y][x][3*W4+3:3*W4] > lastMaxW1))begin
								lastMaxW4 <= weightMemoryAll[y][x][3*W4+3:3*W4];
								W4MaxXloc <= x;
								W4MaxYloc <= y;
							end	
							if((weightMemoryAll[y][x][3*W5+3:3*W5] > 0)&&(weightMemoryAll[y][x][3*W5+3:3*W5] > lastMaxW1))begin
								lastMaxW5 <= weightMemoryAll[y][x][3*W5+3:3*W5];
								W5MaxXloc <= x;
								W5MaxYloc <= y;
							end	
							if((weightMemoryAll[y][x][3*t1+3:3*t1] > 0)&&(weightMemoryAll[y][x][3*t1+3:3*t1] > lastMaxW1))begin
								lastMaxt1 <= weightMemoryAll[y][x][3*t1+3:3*t1];
								t1MaxXloc <= x;
								t1MaxYloc <= y;
							end	                 
							if((weightMemoryAll[y][x][3*t2+3:3*t2] > 0)&&(weightMemoryAll[y][x][3*t2+3:3*t2] > lastMaxW1))begin
								lastMaxt2 <= weightMemoryAll[y][x][3*t2+3:3*t2];
								t2MaxXloc <= x;
								t2MaxYloc <= y;
							end	                  
							if((weightMemoryAll[y][x][3*t3+3:3*t3] > 0)&&(weightMemoryAll[y][x][3*t3+3:3*t3] > lastMaxW1))begin
								lastMaxt3 <= weightMemoryAll[y][x][3*t3+3:3*t3];
								t3MaxXloc <= x;
								t3MaxYloc <= y;
							end	                  
							if((weightMemoryAll[y][x][3*T+3:3*T] > 0)&&(weightMemoryAll[y][x][3*T+3:3*T] > lastMaxW1))begin
								lastMaxT <= weightMemoryAll[y][x][3*T+3:3*T];
								TMaxXloc <= x;
								TMaxYloc <= y;	
							end								
							weightSubState <= SUBSTATE_NEXT_CELL;
						end
						SUBSTATE_NEXT_CELL:begin
							READ <= 1'd0;
							x <= x + 5'd1;
							if(x >= brdWidth)begin
								x <= 5'd0;								
								y <= y + 5'd1;
								weightSubState <= SUBSTATE_READ_WWM;
								if(y >= brdHeight)begin
									y <= 5'd0;
									mainState <= STATE_POINT_CLICK;
								end
							end
						end						
					endcase
					end
					STATE_POINT_CLICK:begin
					     if(~turn)begin // w5 > w4 > T > w3 > t3 > w2 >t2 > w1 > t1 
							if(lastMaxW5 > 0)begin
								XlocClick <= W5MaxXloc;
								YlocClick <= W5MaxYloc;								
							end	
							else if(lastMaxW4 > 0)begin
								XlocClick <= W4MaxXloc;
								YlocClick <= W4MaxYloc;								
							end						
							else if(lastMaxT > 0)begin
								XlocClick <= TMaxXloc;
								YlocClick <= TMaxYloc;								
							end
							else if(lastMaxW3 > 0)begin
								XlocClick <= W3MaxXloc;
								YlocClick <= W3MaxYloc;								
							end
							else if(lastMaxt3 > 0)begin
								XlocClick <= t3MaxXloc;
								YlocClick <= t3MaxYloc;								
							end
							else if(lastMaxW2 > 0)begin
								XlocClick <= W2MaxXloc;
								YlocClick <= W2MaxYloc;								
							end
							else if(lastMaxt2 > 0)begin
								XlocClick <= t2MaxXloc;
								YlocClick <= t2MaxYloc;								
							end
							else if(lastMaxW1 > 0)begin
								XlocClick <= W1MaxXloc;
								YlocClick <= W1MaxYloc;								
							end
							else if(lastMaxt1 > 0)begin
								XlocClick <= t1MaxXloc;
								YlocClick <= t1MaxYloc;								
							end		
							else begin
								XlocClick <= 4'd10;
								YlocClick <= 4'd10;
							end 
						 end
						 else begin//w5 > T > w4 > w3 > t3 > w2 > t2 > w1 > t1
							if(lastMaxW5 > 0)begin
								XlocClick <= W5MaxXloc;
								YlocClick <= W5MaxYloc;								
							end	
							else if(lastMaxT > 0)begin
								XlocClick <= TMaxXloc;
								YlocClick <= TMaxYloc;								
							end						
							else if(lastMaxW4 > 0)begin
								XlocClick <= W4MaxXloc;
								YlocClick <= W4MaxYloc;								
							end
							else if(lastMaxW3 > 0)begin
								XlocClick <= W3MaxXloc;
								YlocClick <= W3MaxYloc;								
							end
							else if(lastMaxt3 > 0)begin
								XlocClick <= t3MaxXloc;
								YlocClick <= t3MaxYloc;								
							end
							else if(lastMaxW2 > 0)begin
								XlocClick <= W2MaxXloc;
								YlocClick <= W2MaxYloc;								
							end
							else if(lastMaxt2 > 0)begin
								XlocClick <= t2MaxXloc;
								YlocClick <= t2MaxYloc;								
							end
							else if(lastMaxW1 > 0)begin
								XlocClick <= W1MaxXloc;
								YlocClick <= W1MaxYloc;								
							end
							else if(lastMaxt1 > 0)begin
								XlocClick <= t1MaxXloc;
								YlocClick <= t1MaxYloc;								
							end	
							else begin
								XlocClick <= 4'd10;
								YlocClick <= 4'd10;
							end 
						 end
						 donePointCal <= 1'd1;
						 mainState <= STATE_CALC_DONE;
					end
					STATE_CALC_DONE:begin						
						mainState <= STATE_START_CALC;
					end
			endcase
		end 
	end	
endmodule 