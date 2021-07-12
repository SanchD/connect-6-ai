module main_tx
    (
        baud_clk,
        reset,
		tx_data_in,
        transmit_en,
        transmit_done_out,
        tx_data_out
    );
    
//------------------------------------------------
// localparams
//------------------------------------------------
    localparam              START_BIT = 1'b0;
    localparam              STOP_BIT = 1'b1;
    
    localparam              STATE_INIT = 0;
    localparam              STATE_TX   = 1;
    localparam              STATE_DONE = 2;
  
//------------------------------------------------
// I/O Signals
//------------------------------------------------
    
    input                   baud_clk;
    input                   reset;
    
    input   [7:0]           tx_data_in;
    input                   transmit_en;
	
    output reg              transmit_done_out;
    output reg              tx_data_out;
    
//------------------------------------------------
// Internal regs and wires
//------------------------------------------------
    reg     [3:0]           counter;
    reg     [7:0]           tx_data_reg;

    integer                 state;
    
//-------------------------------------------------
// Implementation
//------------------------------------------------- 
    always @(posedge baud_clk or posedge reset) begin
        if(reset) begin
            counter <= 4'd0;
            state <= STATE_INIT;
            transmit_done_out <= 1'b0;
        end
        else begin
            case(state)
                STATE_INIT : begin
                    if(transmit_en) begin
                        counter <= 4'd1;
                        tx_data_reg <= tx_data_in;
                        state <= STATE_TX;
                    end
                end
                STATE_TX :  begin
                    if(counter == 10) begin
                        counter <= 4'd0;
                        state <= STATE_DONE;
                        transmit_done_out <= 1'b1;
                    end
                    else begin
                        if (counter != 4'd1) begin
                            tx_data_reg <= tx_data_reg >> 1;
                        end
                        counter <= counter + 4'd1;
                    end
                end
                STATE_DONE : begin
                    if(transmit_en == 1'b0) begin
                        state <= STATE_INIT;
                        transmit_done_out <= 1'b0;
                    end
                end
           endcase
        end
    end
    
    always @(*) begin
        if(reset) begin
            tx_data_out = 1'b1;
        end
        else if (counter == 1) begin
            tx_data_out = START_BIT;
        end
        else if (counter == 10 || counter == 0) begin
            tx_data_out = STOP_BIT;
        end
        else begin
            tx_data_out = tx_data_reg[0];
        end
    end
    
endmodule

