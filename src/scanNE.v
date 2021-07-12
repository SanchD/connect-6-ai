module scanNE(
		input clk,
		input reset,
		input enaScan,
		input colour, //FPGA plays colour = 0 black/ colour = 1 white 
		input [1:0] verticleDataIN ,
		output reg doneScan,
		output reg enaRead,
		output reg enaWRITE,
		output reg [4:0] XlocV,
		output reg [4:0] YlocV,
		output reg [3:0] weight
	);
	
	localparam k = 6;
	localparam brdHeight = 19;
	localparam brdWidth = 19;
	localparam Black = 0;
	localparam White = 1;
	localparam Empty = 2;
	
	localparam W1 = 4'd0;
	localparam W2 = 4'd1;
	localparam W3 = 4'd2;
	localparam W4 = 4'd3;
	localparam W5 = 4'd4;
	localparam t1 = 4'd5;
	localparam t2 = 4'd6;
	localparam t3 = 4'd7;
	localparam T  = 4'd8;
	
	localparam STATE_START_SCAN   = 1;
	localparam STATE_MEMOR_FETCH  = 2;
	localparam STATE_PRCSS_WEIGHT = 3;
	localparam STATE_STORE_WEIGHT = 4;
	localparam STATE_NEXT_WINDOW  = 5;
	localparam STATE_NEXT_LINE 	  = 6;
	
	localparam SUBSTATE_ADRS = 1;
	localparam SUBSTATE_READ = 2;
	
	localparam SUBSTATE_WEIG_CAL_B = 1;
	localparam SUBSTATE_WEIG_CAL_W = 2;
	
	reg [2:0] mainState;
	reg [1:0] memSubstate;
	reg [1:0] weigSubstate;	
	reg [2:0] whiteCount;
	reg [2:0] blackCount;
	reg [4:0] lastEmptyCell;
	reg [5:0] DiagonalNE;
	reg [4:0] x;
	reg [4:0] y;
	reg [4:0] i;
	reg [4:0] j; 
	reg [2:0] z;
	reg [1:0] tempData [0:18];
	
	initial begin
		mainState <= STATE_START_SCAN;
		memSubstate <= SUBSTATE_ADRS;
		weigSubstate <= SUBSTATE_WEIG_CAL_W;
		DiagonalNE <= 6'd5;
		doneScan <= 0;
		weight <= 0;
		x <= 0;
		y <= 0;
		i <= 0;
		j <= 0;
	end
	
	always @ (posedge clk or posedge reset)	begin
		if(reset) begin
			mainState    <= STATE_START_SCAN;
			memSubstate  <= SUBSTATE_ADRS;
			weigSubstate <= SUBSTATE_WEIG_CAL_W;
			DiagonalNE   <= 6'd5;
			doneScan     <= 0;
			weight 		 <= 0;
			x <= 0;
			y <= 4'd5;
			i <= 0;
			j <= 0;
		end
		else begin
			case(mainState)
				STATE_START_SCAN: begin
					if(enaScan)begin
						mainState <= STATE_MEMOR_FETCH;
						doneScan <= 1'd0;
					end
				end
				STATE_MEMOR_FETCH: begin
					if(DiagonalNE < brdHeight)begin
						case(memSubstate)
							SUBSTATE_ADRS: begin
								XlocV <= x;
								YlocV <= DiagonalNE - y;
								enaRead <= 1'd1;
								memSubstate <= SUBSTATE_READ;							
							end
							SUBSTATE_READ: begin
								tempData[x] <= verticleDataIN; 								
								x <= x + 5'd1;
								y <= y + 5'd1;
								if((x > DiagonalNE)||(y > DiagonalNE))begin
									mainState <= STATE_PRCSS_WEIGHT;
									enaRead <= 1'd0;
									x <= 5'd0;
									y <= 5'd0;
								memSubstate <= SUBSTATE_ADRS;
								end									
							end
						endcase
					end
					else begin
						case(memSubstate)
							SUBSTATE_ADRS: begin
								XlocV <= (DiagonalNE - (brdHeight-1'b1)) + x;
								YlocV <= (DiagonalNE - (brdHeight-1'b1)) - y;
								enaRead <= 1'd1;
								memSubstate <= SUBSTATE_READ;							
							end
							SUBSTATE_READ: begin
								tempData[x] <= verticleDataIN; 
								x <= x + 5'd1;
								y <= y + 5'd1;
								if(XlocV > (brdHeight-1))begin
									mainState <= STATE_PRCSS_WEIGHT;
									enaRead <= 1'd0;
									x <= 5'd0;
									y <= 5'd0;
								end										
								memSubstate <= SUBSTATE_ADRS;
							end
						endcase										
					end
				end
				STATE_PRCSS_WEIGHT:begin
					if(tempData[i+j] == Black)begin
						blackCount <= blackCount + 3'd1;
					end
					else if(tempData[i+j] == White)begin
						whiteCount <= whiteCount + 3'd1;
					end
					else if(tempData[i+j] == Empty)begin
						lastEmptyCell <= i+j;
					end
					j = j + 3'd1;
					if(j >= k)begin
						j <= 0;
						mainState <= STATE_STORE_WEIGHT;
					end
				end
				STATE_STORE_WEIGHT:begin
					if(tempData[i+j] == Empty)begin
						case(weigSubstate)
							SUBSTATE_WEIG_CAL_B:begin
								if( blackCount > 0 )begin							
									if(colour && (blackCount > 3))begin
										if(DiagonalNE < brdHeight)begin
										
											XlocV <= lastEmptyCell;
											YlocV <= DiagonalNE - lastEmptyCell;
											weight <= T;
										end
										else begin
											XlocV <= (DiagonalNE - (brdHeight-1'b1)) + lastEmptyCell;
											YlocV <= (brdHeight-1'b1) - lastEmptyCell;
											weight <= T;
										end
										enaWRITE <= 1'd1;
									end
									else begin
										if(DiagonalNE < brdHeight)begin
											XlocV <= i+j;
											YlocV <= DiagonalNE - (i+j);
										end
										else begin
											XlocV <= (DiagonalNE - (brdHeight-1'b1)) + (i+j);
											YlocV <= (brdHeight-1'b1) - (i+j);
										end	
										if(colour)begin
											weight <= W5 + blackCount;
										end 
										else begin
											weight <= blackCount;
										end
										blackCount <= 0;
										enaWRITE <= 1'd1;
									end
								end
								weigSubstate <= SUBSTATE_WEIG_CAL_W;
							end
							SUBSTATE_WEIG_CAL_W:begin
								if( whiteCount > 0 )begin							
									if((~colour) && (whiteCount > 3))begin
										if(DiagonalNE < brdHeight)begin
											XlocV <= lastEmptyCell;
											YlocV <= DiagonalNE - lastEmptyCell;
											weight <= T;
										end
										else begin
											XlocV <= (DiagonalNE - (brdHeight-1'b1)) + lastEmptyCell;
											YlocV <= (brdHeight-1'b1) - lastEmptyCell;
											weight <= T;
										end
										enaWRITE <= 1'd1;
									end	
									else begin
										if(DiagonalNE < brdHeight)begin
											XlocV <= i+j;
											YlocV <= DiagonalNE - (i+j);
										end
										else begin
											XlocV <= (DiagonalNE - (brdHeight-1'b1)) + (i+j);
											YlocV <= (brdHeight-1'b1) - (i+j);
										end	
										if(colour)begin
											weight <= whiteCount;
										end 
										else begin
											weight <= W5 + whiteCount;
										end	
										whiteCount <= 0;
										enaWRITE <= 1'd1;										
									end
								end
								weigSubstate <= SUBSTATE_WEIG_CAL_B;
								j = j + 3'd1;
								if(j >= k)begin
									j <= 0;
									mainState <= STATE_NEXT_WINDOW;
								end
							end
						endcase
						end
					end 
				STATE_NEXT_WINDOW: begin
					enaWRITE <= 1'd0;
					i <= i + (3'd1);
					mainState <= STATE_PRCSS_WEIGHT;
					if(i > (DiagonalNE + 1 - k))begin
						mainState <= STATE_NEXT_LINE;
						i <= 0;
					end
				end
				STATE_NEXT_LINE: begin
					DiagonalNE = DiagonalNE + 3'd1;
					mainState <= STATE_MEMOR_FETCH;
					if(DiagonalNE >= (brdHeight + brdWidth - 1 - k))begin
						mainState <= STATE_START_SCAN;
						doneScan <= 1'd1;
						DiagonalNE <= 0;
					end
				end
			endcase
		end;
	end
endmodule 