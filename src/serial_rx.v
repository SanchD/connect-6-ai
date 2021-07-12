`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:    Manupa
// 
// Create Date:    16:15:37 08/22/2012 
// Design Name: 
// Module Name:    serial_rx 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module serial_rx
    (
        clk,
        reset,
        enable,
        rxdata_in,
        rxdata_out,
        rxdata_error_out,
        rxdata_valid_out,
        rxdata_baud_clk_out,
        rxdata_baud8_clk_out
    );
    
    
//---------------------------------------------------------------------------------------------------------------------
// parameter definitions
//---------------------------------------------------------------------------------------------------------------------
    parameter   					HIGH_CLK    = 50_000_000;
    parameter   					BAUD_CLK    = 115_200;
   
//---------------------------------------------------------------------------------------------------------------------
// localparams
//---------------------------------------------------------------------------------------------------------------------
    localparam						BAUD8_CLK   = BAUD_CLK*15; 
	
	localparam              	    STATE_INIT = 0;
    localparam              	    STATE_BIT0 = 1;
    localparam              	    STATE_BIT1 = 2;
    localparam              	    STATE_BIT2 = 3;
    localparam              	    STATE_BIT3 = 4;
    localparam              	    STATE_BIT4 = 5;
    localparam              	    STATE_BIT5 = 6;
    localparam              	    STATE_BIT6 = 7;
    localparam              	    STATE_BIT7 = 8;
    localparam              	    STATE_STOP = 9;
    
//---------------------------------------------------------------------------------------------------------------------
// I/O Signal
//---------------------------------------------------------------------------------------------------------------------
    input                           clk;
    input                           reset;
    input                           enable;
    
    input                           rxdata_in;
    
    output reg  [7:0]               rxdata_out;
	output reg                      rxdata_error_out;
	output reg                     	rxdata_valid_out;
	
    output                          rxdata_baud_clk_out;
    output                          rxdata_baud8_clk_out;

//---------------------------------------------------------------------------------------------------------------------
// Regs and wires
//---------------------------------------------------------------------------------------------------------------------  
    wire                            baud_clk_int;
    wire                            baud8_clk_int;
    
    reg                             rxdata_clean_int;
    reg                             rxdata_clean_valid;
    
    reg [3:0]                       rxbuffer;
    reg [3:0]                       rxstate;
    reg [7:0]                       rxdata_out_reg;
	
    reg [3:0]                       counter;
    reg [3:0]                       counter2;
//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------

    baudgen
    #(
        .HIGH_CLK       (HIGH_CLK),
        .BAUD_CLK       (BAUD_CLK)
    )
    baudgen_115200_block
    (
        .reset          (reset),
        .enable         (1'b1),
        
        .high_clk_in    (clk),
        .baud_clk_out   (baud_clk_int)
    );
   
	
   baudgen
    #(
        .HIGH_CLK       (HIGH_CLK),
        .BAUD_CLK       (BAUD8_CLK)
    )
    baudgen_115200_into_8_block
    (
        .reset          (reset),
        .enable         (1'b1),
        
        .high_clk_in    (clk),
        .baud_clk_out   (baud8_clk_int)
    );
	
	assign rxdata_baud_clk_out = baud_clk_int;
    assign rxdata_baud8_clk_out = baud8_clk_int;
	

    always @(posedge clk or posedge reset) begin : noise_canceller
        if(reset) begin
            rxbuffer <= 4'b0101;
        end
        else if (enable) begin
            rxbuffer[0] <= rxdata_in;
            rxbuffer[3:1] <= {rxbuffer[2],rxbuffer[1],rxbuffer[0]};
        end
    end
    
	
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            rxdata_clean_int <= 1'bx;
            rxdata_clean_valid <= 1'b0;
        end
        else if(enable) begin
            if(&rxbuffer) begin
                rxdata_clean_int <= 1'b1;
                rxdata_clean_valid <= 1'b1;
            end
            else if(~(|rxbuffer)) begin
                rxdata_clean_int <= 1'b0;
                rxdata_clean_valid <= 1'b1;
            end
        end
    end
    
	
	always @( posedge baud8_clk_int or posedge reset ) begin
		if(reset) begin
              rxstate <= STATE_INIT;
			  rxdata_out_reg <= 0;
			  rxdata_valid_out <= 0;
			  rxdata_error_out <= 0;
              counter <= 4'd0;
              counter2 <= 4'd0;
		end
		else if(enable) begin
			case(rxstate)
			
				STATE_INIT : begin
                    if(counter == 4'd0) begin
                        if(rxdata_clean_valid) begin
                            if(rxdata_clean_int == 1'b0 ) begin
                                rxdata_error_out <= 1'b0;
								rxdata_valid_out <= 1'b0;
                                counter <= counter + 4'd1;
                            end
                            else begin
                                rxstate <= STATE_INIT;
                                if(counter2 == 4'd15) begin
                                    rxdata_valid_out <= 1'b0;
                                    counter2 <= 4'd0;
                                end
                                else begin
                                    counter2 <= counter2 + 4'd1;
                                end
                            end
                        end
                    end
                    else if(counter == 4'd15) begin
                        counter <= 4'd0;
                        counter2 <= 4'd0;
                        rxstate <= STATE_BIT0;
                    end
                    else begin
                        counter <= counter + 4'd1;
                    end
				end
				STATE_BIT0 : begin
                    if(counter == 4'd0) begin
                        if(rxdata_clean_valid) begin

                          rxdata_out_reg[0] <= rxdata_clean_int;
                          counter <= counter + 4'd1;
                        end
                    end
                    else if(counter == 4'd15) begin
                        counter <= 4'd0;
                        rxstate <= STATE_BIT1;
                    end
                    else begin
                        counter <= counter + 4'd1;
                    end
				end
				STATE_BIT1 : begin
                    if(counter == 4'd0) begin
                        if(rxdata_clean_valid) begin

                          rxdata_out_reg[1] <= rxdata_clean_int;
                          counter <= counter + 4'd1;
                        end
                    end
                    else if(counter == 4'd15) begin
                        counter <= 4'd0;
                        rxstate <= STATE_BIT2;
                    end
                    else begin
                        counter <= counter + 4'd1;
                    end
				end
				STATE_BIT2 : begin
                    if(counter == 4'd0) begin
                        if(rxdata_clean_valid) begin

                          rxdata_out_reg[2] <= rxdata_clean_int;
                          counter <= counter + 4'd1;
                        end
                    end
                    else if(counter == 4'd15) begin
                        counter <= 4'd0;
                        rxstate <= STATE_BIT3;
                    end
                    else begin
                        counter <= counter + 4'd1;
                    end
				end
				STATE_BIT3 : begin
                    if(counter == 4'd0) begin
                        if(rxdata_clean_valid) begin

                          rxdata_out_reg[3] <= rxdata_clean_int;
                          counter <= counter + 4'd1;
                        end
                    end
                    else if(counter == 4'd15) begin
                        counter <= 4'd0;
                        rxstate <= STATE_BIT4;
                    end
                    else begin
                        counter <= counter + 4'd1;
                    end
				end
				STATE_BIT4 : begin
                    if(counter == 4'd0) begin
                        if(rxdata_clean_valid) begin

                          rxdata_out_reg[4] <= rxdata_clean_int;
                          counter <= counter + 4'd1;
                        end
                    end
                    else if(counter == 4'd15) begin
                        counter <= 4'd0;
                        rxstate <= STATE_BIT5;
                    end
                    else begin
                        counter <= counter + 4'd1;
                    end
				end
				STATE_BIT5 : begin
                    if(counter == 4'd0) begin
                        if(rxdata_clean_valid) begin

                          rxdata_out_reg[5] <= rxdata_clean_int;
                          counter <= counter + 4'd1;
                        end
                    end
                    else if(counter == 4'd15) begin
                        counter <= 4'd0;
                        rxstate <= STATE_BIT6;
                    end
                    else begin
                        counter <= counter + 4'd1;
                    end
				end
				STATE_BIT6 : begin
                    if(counter == 4'd0) begin
                        if(rxdata_clean_valid) begin

                          rxdata_out_reg[6] <= rxdata_clean_int;
                          counter <= counter + 4'd1;
                        end
                    end
                    else if(counter == 4'd15) begin
                        counter <= 4'd0;
                        rxstate <= STATE_BIT7;
                    end
                    else begin
                        counter <= counter + 4'd1;
                    end
				end
				STATE_BIT7 : begin
                    if(counter == 4'd0) begin
                        if(rxdata_clean_valid) begin

                          rxdata_out_reg[7] <= rxdata_clean_int;
                          counter <= counter + 4'd1;
                        end
                    end
                    else if(counter == 4'd15) begin
                        counter <= 4'd0;
                        rxstate <= STATE_STOP;
                    end
                    else begin
                        counter <= counter + 4'd1;
                    end
				end
				STATE_STOP : begin
                    if(rxdata_clean_valid) begin
                        if(counter == 4'd0) begin
                            counter <= 4'd0;
                            rxstate <= STATE_INIT;
                            if ( rxdata_clean_int == 1'b1 ) begin
                                rxdata_error_out <= 1'b0;
                                rxdata_out <= rxdata_out_reg;
                                rxdata_valid_out <= 1'b1;
                            end
                            else begin
                                rxdata_out <= rxdata_out_reg;
                                rxdata_error_out <= 1'b1;
                                rxdata_valid_out <= 1'b1;
                            end
                        end
                        else begin
                            counter <= counter + 4'd1;
                        end
                    end
				 end
			endcase   
		end
	end
	
   
endmodule
