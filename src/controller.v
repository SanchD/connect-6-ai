module controller(
	input clk,
	input reset,
	input data_in,
	output data_out
	);
	
	localparam   HIGH_CLK    = 50_000_000;
    localparam   BAUD_CLK    = 115_200;	
	
	localparam 	 Black = 2'd0;
	localparam 	 White = 2'd1;

	localparam 	 STATE_START_RX				= 2'd0;
	localparam 	 STATE_RX_CHAR				= 2'd1;
	localparam 	 STATE_RX_DONE				= 2'd2;
    
	localparam 	 SUBSTATE_RX_COLOUR			= 4'd0;
	localparam 	 SUBSTATE_RX_Y1_10			= 4'd1;
	localparam 	 SUBSTATE_RX_Y1_1			= 4'd2;
	localparam 	 SUBSTATE_RX_X1_10			= 4'd3;
	localparam 	 SUBSTATE_RX_X1_1			= 4'd4;
	localparam 	 SUBSTATE_RX_Y2_10			= 4'd5;
	localparam 	 SUBSTATE_RX_Y2_1			= 4'd6;
	localparam 	 SUBSTATE_RX_X2_10			= 4'd7;
	localparam 	 SUBSTATE_RX_X2_1			= 4'd8;

	localparam 	 STATE_RX_DATA_DECODE		= 3'd0;
	localparam 	 STATE_STORE_DATA_BM		= 3'd1;
	localparam 	 STATE_WEIGHT_GEN			= 3'd2;
	localparam 	 STATE_POINT_CALCULATE		= 3'd3;
	localparam 	 STATE_TX_POINT				= 3'd4;
 	 
	localparam 	 SUBSTATE_STORE_STONE_1		= 2'd0;
	localparam 	 SUBSTATE_STORE_STONE_2		= 2'd1;
	localparam 	 SUBSTATE_STORE_STONE_DONE	= 2'd2;

	localparam 	 SUBSTATE_START_WEIGHT_GEN	= 2'd0;
	localparam 	 SUBSTATE_DONE_WEIGHT_GEN	= 2'd1;
 
	localparam 	 SUBSTATE_START_POINT_CALC	= 2'd0;
	localparam 	 SUBSTATE_DONE_POINT_CALC	= 2'd1;

	localparam 	 STATE_START_TX				= 3'd0;
	localparam 	 STATE_TX_CHAR_Y_10			= 3'd1;
	localparam 	 STATE_TX_CHAR_Y_1			= 3'd2;
	localparam 	 STATE_TX_CHAR_X_10			= 3'd3;
	localparam 	 STATE_TX_CHAR_X_1			= 3'd4;
	localparam 	 STATE_TX_DONE				= 3'd5;
	
	wire baud_clk;
    wire [7:0] rx_data;
	wire rxdata_valid;
	reg [7:0] tx_data;
	reg tx_enable;
	wire tx_done;
    wire baud8_clk;
	
	wire [4:0] XlocV;
	wire [4:0] YlocV;
	wire [4:0] XlocH;
	wire [4:0] YlocH;
	wire [4:0] XlocNE;
	wire [4:0] YlocNE;
	wire [4:0] XlocNW;
	wire [4:0] YlocNW;
	wire bmRead;
	wire enaReadV;
	wire enaReadH;
	wire enaReadNE;
	wire enaReadNW;
	wire doneScan;
	wire doneScanV;
	wire doneScanH;
	wire doneScanNE;
	wire doneScanNW;
	wire [1:0] verticleDataOUT;
	wire [1:0] horizontalDataOUT;
	wire [1:0] NEDataOUT;
	wire [1:0] NWDataOUT;
	wire [3:0] weightV;
	wire [3:0] weightH;
	wire [3:0] weightNE;
	wire [3:0] weightNW;
	wire weightMemReset;
	wire [26:0] WmDataOUTV;
	wire [26:0] WmDataOUTH;
	wire [26:0] WmDataOUTNE;
	wire [26:0] WmDataOUTNW;
	wire [4:0] pointCalX;
	wire [4:0] pointCalY;
	wire pointCalRead;
	wire donePointCal;
	wire [4:0] XlocClick;
	wire [4:0] YlocClick;
	wire wmWRITEV;
	wire wmWRITEH;
	wire wmWRITENE;
	wire wmWRITENW;

	reg [1:0] RXState;
	reg [3:0] RXcharSUbsate;
	reg [2:0] mainState;
	reg [1:0] strBMsubState;
	reg [1:0] weightGenSubstate;
	reg [1:0] pointCalSubstate;
	reg [2:0] TXState;

	reg [4:0] bmXloc;
	reg [4:0] bmYloc;
	reg [1:0] dataIN;
	reg [1:0] x;
	reg [4:0] locations [0:3]; //4 memory cells that are 5 bits wide
	reg colour;
	reg turn;
	reg enaWeightgen;
	reg enaPointCal;
	reg txDataReady;

	reg rxEnable;
	reg rxDone;
	reg txDone;
	reg bmWRITE;
	reg wmReset;
	
	main_tx tx_engine
    (
        .baud_clk 			(baud_clk),
        .reset				(~reset),
		.tx_data_in			(tx_data),
        .transmit_en 		(tx_enable),
        .transmit_done_out 	(tx_done),
        .tx_data_out 		(data_out)
    );

    serial_rx
    #(
        .HIGH_CLK       (HIGH_CLK),
        .BAUD_CLK       (BAUD_CLK)
    )
    rx_engine
    (
        .clk 					(clk),
        .reset 					(~reset),
        .enable 				(rxEnable),
        .rxdata_in    			(data_in),
        .rxdata_out 			(rx_data),
        .rxdata_error_out 		(),
        .rxdata_valid_out 		(rxdata_valid),
        .rxdata_baud_clk_out 	(baud_clk),
        .rxdata_baud8_clk_out 	(baud8_clk)
    );

	boardMemory bM(
		.clk 					(clk),
		.reset					(~reset),
		.READ					(bmRead),
		.WRITE					(bmWRITE),
		.Xloc					(bmXloc),
		.Yloc					(bmYloc),
		.dataIN					(dataIN),
		.XlocV					(XlocV),
		.YlocV					(YlocV),
		.XlocH					(XlocH),
		.YlocH					(YlocH),
		.XlocNE					(XlocNE),
		.YlocNE					(YlocNE),
		.XlocNW					(XlocNW),
		.YlocNW					(YlocNW),
		.verticleDataOUT		(verticleDataOUT),
		.horizontalDataOUT		(horizontalDataOUT),
		.NEDataOUT				(NEDataOUT),
		.NWDataOUT				(NWDataOUT)
	);	                       

	scanHrzntl Scan_Horizontal(
		.clk 					(clk),
		.reset					(~reset),
		.enaScan				(enaWeightgen),
		.colour					(colour), //FPGA plays colour = 0 black/ colour = 1 white 
		.verticleDataIN			(horizontalDataOUT),
		.doneScan				(doneScanH),
		.enaRead				(enaReadH),
		.enaWRITE				(wmWRITEH),
		.XlocV					(XlocH),
		.YlocV					(YlocH),
		.weight					(weightH)
	);

	scanVrtcl Scan_Verticle(
		.clk 					(clk),
		.reset					(~reset),
		.enaScan				(enaWeightgen),
		.colour					(colour), //FPGA plays colour = 0 black/ colour = 1 white 
		.verticleDataIN 		(verticleDataOUT),
		.doneScan				(doneScanV),
		.enaRead				(enaReadV),
		.enaWRITE				(wmWRITEV),
		.XlocV					(XlocV),
		.YlocV					(YlocV),
		.weight					(weightV)
	);	

	scanNE Scan_North_East(
		.clk 					(clk),
		.reset					(~reset),
		.enaScan				(enaWeightgen),
		.colour					(colour), //FPGA plays colour = 0 black/ colour = 1 white 
		.verticleDataIN 		(NEDataOUT),
		.doneScan				(doneScanNE),
		.enaRead				(enaReadNE),
		.enaWRITE				(wmWRITENE),
		.XlocV					(XlocNE),
		.YlocV					(YlocNE),
		.weight					(weightNE)
	);
	
	scanNW Scan_North_West(
		.clk 					(clk),
		.reset					(~reset),
		.enaScan				(enaWeightgen),
		.colour					(colour), //FPGA plays colour = 0 black/ colour = 1 white 
		.verticleDataIN 		(NWDataOUT),
		.doneScan				(doneScanNW),
		.enaRead				(enaReadNW),
		.enaWRITE				(wmWRITENW),
		.XlocV					(XlocNW),
		.YlocV					(YlocNW),
		.weight					(weightNW)
	);

	weightMemory Horizontal_Data_wM(
		.clk 					(clk),
		.reset					(weightMemReset),
		.READ					(pointCalRead),
		.WRITE					(wmWRITEH),
		.weight					(weightH),
		.Xloc					(XlocH),
		.Yloc					(YlocH),
		.XlocOUT				(pointCalX),
		.YlocOUT				(pointCalY),
		.dataOUT				(WmDataOUTH)
	);

	weightMemory Verticle_Data_wM(
		.clk 					(clk),
		.reset					(weightMemReset),
		.READ					(pointCalRead),
		.WRITE					(wmWRITEV),
		.weight					(weightV),
		.Xloc					(XlocV),
		.Yloc					(YlocV),
		.XlocOUT				(pointCalX),
		.YlocOUT				(pointCalY),
		.dataOUT				(WmDataOUTV)
	);

	weightMemory North_East_Data_wM(
		.clk 					(clk),
		.reset					(weightMemReset),
		.READ					(pointCalRead),
		.WRITE					(wmWRITENE),
		.weight					(weightNE),
		.Xloc					(XlocNE),
		.Yloc					(YlocNE),
		.XlocOUT				(pointCalX),
		.YlocOUT				(pointCalY),
		.dataOUT				(WmDataOUTNE)
	);

	weightMemory North_West_Data_wM(
		.clk 					(clk),
		.reset					(weightMemReset),
		.READ					(pointCalRead),
		.WRITE					(wmWRITENW),
		.weight					(weightNW),
		.Xloc					(XlocNW),
		.Yloc					(YlocNW),
		.XlocOUT				(pointCalX),
		.YlocOUT				(pointCalY),
		.dataOUT				(WmDataOUTNW)
	);	

	pointCal Calculation_Clicking_Point(
		.clk 					(clk),
		.reset					(~reset),
		.enaPointCal			(enaPointCal),
		.turn      				(turn),
		.dataINV				(WmDataOUTV),
		.dataINH				(WmDataOUTH),
		.dataINNE				(WmDataOUTNE),
		.dataINNW				(WmDataOUTNW),
		.donePointCal			(donePointCal),
		.READ					(pointCalRead),
		.XlocV					(pointCalX),
		.YlocV					(pointCalY),	
		.XlocClick				(XlocClick),
		.YlocClick				(YlocClick)
	);
	
	assign bmRead = enaReadV || enaReadH || enaReadNE || enaReadNW;
	assign doneScan = doneScanV && doneScanH && doneScanNE && doneScanNW;
	assign weightMemReset = (~reset)||wmReset;
	
	initial begin
		rxEnable <= 1'd0;
		colour <= 1'd0;
		enaWeightgen <= 1'd0;
		turn <= 1'd0;
		strBMsubState <= SUBSTATE_STORE_STONE_2;
	end
	
	always @ (posedge baud_clk or posedge reset)begin
		if(reset)begin
			locations[0] <= 1'd0;
			locations[1] <= 1'd0;
			locations[2] <= 1'd0;
			locations[3] <= 1'd0;
			RXState <= STATE_START_RX;
			RXcharSUbsate <= SUBSTATE_RX_COLOUR;
		end
		else begin 
			case(RXState)
				STATE_START_RX:begin
					if(rxEnable && (~rxDone))
					RXState <= STATE_RX_CHAR;
					else
					RXState <= STATE_START_RX;
				end
				STATE_RX_CHAR:begin
						case(RXcharSUbsate)
							SUBSTATE_RX_COLOUR:begin
								if(rxdata_valid)begin
									if(rx_data == "W")begin			//White
										colour <= White;
										RXcharSUbsate <= SUBSTATE_RX_Y2_10;
									end
									else if(rx_data == "B")begin				//Black
										colour <= Black;										
										RXcharSUbsate <= SUBSTATE_RX_Y2_10;
									end	
								end
								else begin
									RXcharSUbsate <= SUBSTATE_RX_COLOUR;
								end
							end
							SUBSTATE_RX_Y1_10:begin
								if(rxdata_valid)begin
									locations[0] <= (rx_data - 8'd48)*10; 
									RXcharSUbsate <= SUBSTATE_RX_Y1_1;
								end
								else begin
									RXcharSUbsate <= SUBSTATE_RX_Y2_10;
								end							
							end
							SUBSTATE_RX_Y1_1:begin
								if(rxdata_valid)begin
									locations[0] <= locations[0] + (rx_data - 8'd48) - 5'd1;									
									RXcharSUbsate <= SUBSTATE_RX_X1_10;	
								end
								else begin
									RXcharSUbsate <= SUBSTATE_RX_Y1_1;
								end														
							end
							SUBSTATE_RX_X1_10:begin
								if(rxdata_valid)begin
									locations[1] <= (rx_data - 8'd48)*10; 
									RXcharSUbsate <= SUBSTATE_RX_X1_1;
								end
								else begin
									RXcharSUbsate <= SUBSTATE_RX_X1_10;
								end									
							end
							SUBSTATE_RX_X1_1:begin
								if(rxdata_valid)begin
									locations[1] <= locations[1] + (rx_data - 8'd48) - 5'd1;
									RXcharSUbsate <= SUBSTATE_RX_Y2_10;									
								end
								else begin
									RXcharSUbsate <= SUBSTATE_RX_X1_1;
								end
							end
							SUBSTATE_RX_Y2_10:begin
								if(rxdata_valid)begin
									locations[2] <= (rx_data - 8'd48)*10;	
									RXcharSUbsate <= SUBSTATE_RX_Y2_1;
								end
								else begin
									RXcharSUbsate <= SUBSTATE_RX_Y2_10;
								end
							end
							SUBSTATE_RX_Y2_1:begin
								if(rxdata_valid)begin
									locations[2] <= locations[2] + (rx_data - 8'd48) - 5'd1;
									RXcharSUbsate <= SUBSTATE_RX_X2_10;
								end
								else begin
									RXcharSUbsate <= SUBSTATE_RX_Y2_1;
								end								
							end
							SUBSTATE_RX_X2_10:begin
								if(rxdata_valid)begin
									locations[3] <= (rx_data - 8'd48)*10;
									RXcharSUbsate <= SUBSTATE_RX_X2_1;
								end
								else begin
									RXcharSUbsate <= SUBSTATE_RX_X2_10;
								end								
							end
							SUBSTATE_RX_X2_1:begin
								if(rxdata_valid)begin
									locations[3] <= locations[3] + (rx_data - 8'd48) - 5'd1;
									RXcharSUbsate <= SUBSTATE_RX_Y1_10;
									RXState <= STATE_RX_DONE;
								end
								else begin
									RXcharSUbsate <= SUBSTATE_RX_X2_1;
								end								
							end
						endcase					
				end
				STATE_RX_DONE:begin
					rxDone <= 1'd1;
					RXState <= STATE_START_RX;
				end					
			endcase			
		end
	end
	
	always @ (posedge clk or posedge reset)begin
		if(reset)begin
			rxEnable <= 1'd0;
			strBMsubState <= SUBSTATE_STORE_STONE_2;
			enaWeightgen <= 0;
			txDataReady <= 0;
			
			mainState <= STATE_RX_DATA_DECODE;
		end
		else begin
		case(mainState)
			STATE_RX_DATA_DECODE:begin
				if(rxDone)begin					
					rxEnable <= 1'd1;
					mainState <= STATE_STORE_DATA_BM;
				end
				else begin
					mainState <= STATE_RX_DATA_DECODE;
					rxEnable <= 1'd1;
				end	
			end
			STATE_STORE_DATA_BM:begin
				bmWRITE <= 1'd1;
				case(strBMsubState)
					SUBSTATE_STORE_STONE_1:begin
						bmYloc <= locations[0];
						bmXloc <= locations[1];
						dataIN <= ~colour;
						strBMsubState <= SUBSTATE_STORE_STONE_2;
					end
					SUBSTATE_STORE_STONE_2:begin
						bmYloc <= locations[2];
						bmXloc <= locations[3];
						dataIN <= ~colour;
						strBMsubState <= SUBSTATE_STORE_STONE_DONE;
					end
					SUBSTATE_STORE_STONE_DONE:begin						
						bmWRITE <= 1'd0;
						strBMsubState <= SUBSTATE_STORE_STONE_1;
						mainState <= STATE_WEIGHT_GEN;
					end
				endcase			
			end
			STATE_WEIGHT_GEN:begin
				case(weightGenSubstate)
					SUBSTATE_START_WEIGHT_GEN:begin						
						if((~enaWeightgen)&& weightMemReset)begin
							wmReset <= 1'd0;
							enaWeightgen <= 1'd1;
							weightGenSubstate <= SUBSTATE_DONE_WEIGHT_GEN;
						end
						else begin
							weightGenSubstate <= SUBSTATE_START_WEIGHT_GEN;
							wmReset <= 1'd1;
						end
					end
					SUBSTATE_DONE_WEIGHT_GEN:begin
						if(doneScan)begin
							enaWeightgen <= 0;
							weightGenSubstate <= SUBSTATE_START_WEIGHT_GEN;
							mainState <= STATE_POINT_CALCULATE;
						end
						else begin
							weightGenSubstate <= SUBSTATE_DONE_WEIGHT_GEN;
							enaWeightgen <= 0;
						end
					end
				endcase
			end
			STATE_POINT_CALCULATE:begin
				bmWRITE <= 1'd0;
				case(pointCalSubstate)
					SUBSTATE_START_POINT_CALC:begin
						if(~enaPointCal)begin
							enaPointCal <= 1'd1;
							pointCalSubstate <= SUBSTATE_DONE_POINT_CALC;
						end
						else begin
							enaPointCal <= 1'd0;
							pointCalSubstate <= SUBSTATE_START_POINT_CALC;
						end
					end
					SUBSTATE_DONE_POINT_CALC:begin
						if(donePointCal)begin
							enaPointCal <= 0;
							pointCalSubstate <= SUBSTATE_START_POINT_CALC;
							mainState <= STATE_TX_POINT;	
							txDataReady <= 1;
						end
						else begin
							pointCalSubstate <= SUBSTATE_DONE_POINT_CALC;
							enaWeightgen <= 0;
						end
					end					
				endcase
			end
			STATE_TX_POINT:begin
				bmWRITE <= 1'd1;
				bmYloc <= XlocClick;
				bmXloc <= YlocClick;
				dataIN <= colour;
				if(txDone)begin					
					if(turn >= 1'd1)begin
						txDataReady <= 1'd0;
						mainState <= STATE_RX_DATA_DECODE;
						turn <= 1'd0;
						bmWRITE <= 1'd0;
					end
					else begin						
						turn <= turn + 1'd1;
						txDataReady <= 1'd0;
						mainState <= STATE_POINT_CALCULATE;
					end
				end
				else begin
					mainState <= STATE_TX_POINT;
				end
			end
		endcase
		end	
	end	
	
	always @ (posedge baud_clk or posedge reset)begin
		if(reset)begin
			tx_enable <= 0;		
			TXState <= STATE_START_RX;
		end
		else begin 
			case(TXState)
				STATE_START_TX:begin
					if(txDataReady)begin
						tx_enable <= 1'd1;
						TXState <= STATE_TX_CHAR_Y_10;
						if(XlocClick > 5'd8)
							tx_data <= 8'd49;
						else
							tx_data <= 8'd48;
					end
					else begin
						TXState <= STATE_START_TX;
					end
				end
				STATE_TX_CHAR_Y_10:begin					
					if(tx_done) begin
						TXState <= STATE_TX_CHAR_Y_1;
						tx_enable <= 1'd1;
						if(XlocClick + 5'd1 > 5'd9)
							tx_data <= (XlocClick + 8'd39);
						else
							tx_data <= XlocClick + 8'd49;
					end
					else begin
						tx_enable <= 1'b0;
						TXState <= STATE_TX_CHAR_Y_10;
					end					
				end
				STATE_TX_CHAR_Y_1:begin
					if(tx_done) begin
						TXState <= STATE_TX_CHAR_X_10;
						tx_enable <= 1'd1;
						if(YlocClick > 5'd8)
							tx_data <= 8'd49;
						else
							tx_data <= 8'd48;
					end
					else begin
						tx_enable <= 1'b0;
						TXState <= STATE_TX_CHAR_Y_1;
					end						
				end
				STATE_TX_CHAR_X_10:begin
					if(tx_done) begin
						TXState <= STATE_TX_CHAR_X_1;
						tx_enable <= 1'd1;
						if(YlocClick > 5'd8)
							tx_data <= (YlocClick + 8'd39);
						else
							tx_data <= YlocClick + 8'd49;
					end
					else begin
						tx_enable <= 1'b0;
						TXState <= STATE_TX_CHAR_X_10;
					end	
				end	
				STATE_TX_CHAR_X_1:begin
					if(tx_done) begin
						TXState <= STATE_TX_DONE;
						tx_enable <= 1'd0;
						tx_data <= 8'd0;
					end
					else begin
						tx_enable <= 1'b0;
						TXState <= STATE_TX_CHAR_X_1;
					end	
				end	
				STATE_TX_DONE:begin
					txDone <= 1'd1;
				end
			endcase
		end
	end
endmodule 