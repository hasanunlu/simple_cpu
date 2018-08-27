`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:17:05 04/23/2013 
// Design Name: 
// Module Name:    uart_rc 
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
module uart_rc(
				input clk,
				input RxD,
				output reg RxD_data_ready,  
				output reg [7:0] RxD_data,
				output reg RxD_endofpacket,  
				output RxD_idle  
				);

parameter ClkFrequency = 50000000; // 50MHz
parameter Baud = 115200;
parameter Baud8 = Baud*8;
parameter Baud8GeneratorAccWidth = 16;

wire [Baud8GeneratorAccWidth:0] Baud8GeneratorInc = ((Baud8<<(Baud8GeneratorAccWidth-7))+(ClkFrequency>>8))/(ClkFrequency>>7);
reg [Baud8GeneratorAccWidth:0] Baud8GeneratorAcc;
always @(posedge clk) Baud8GeneratorAcc <= Baud8GeneratorAcc[Baud8GeneratorAccWidth-1:0] + Baud8GeneratorInc;
wire Baud8Tick = Baud8GeneratorAcc[Baud8GeneratorAccWidth];

reg [1:0] RxD_sync_inv;
always @(posedge clk) if(Baud8Tick) RxD_sync_inv <= {RxD_sync_inv[0], ~RxD};

reg [1:0] RxD_cnt_inv;
reg RxD_bit_inv;

always @(posedge clk)
if(Baud8Tick)
begin
	if( RxD_sync_inv[1] && RxD_cnt_inv!=2'b11) RxD_cnt_inv <= RxD_cnt_inv + 2'h1;
	else 
	if(~RxD_sync_inv[1] && RxD_cnt_inv!=2'b00) RxD_cnt_inv <= RxD_cnt_inv - 2'h1;

	if(RxD_cnt_inv==2'b00) RxD_bit_inv <= 1'b0;
	else
	if(RxD_cnt_inv==2'b11) RxD_bit_inv <= 1'b1;
end

reg [3:0] state;
reg [3:0] bit_spacing;


wire next_bit = (bit_spacing==4'd10);

always @(posedge clk)
if(state==0)
	bit_spacing <= 4'b0000;
else
if(Baud8Tick)
	bit_spacing <= {bit_spacing[2:0] + 4'b0001} | {bit_spacing[3], 3'b000};

always @(posedge clk)
	if(Baud8Tick)
		case(state)
			4'b0000: if(RxD_bit_inv) state <= 4'b1000;  // start bit found?
			4'b1000: if(next_bit) state <= 4'b1001;  // bit 0
			4'b1001: if(next_bit) state <= 4'b1010;  // bit 1
			4'b1010: if(next_bit) state <= 4'b1011;  // bit 2
			4'b1011: if(next_bit) state <= 4'b1100;  // bit 3
			4'b1100: if(next_bit) state <= 4'b1101;  // bit 4
			4'b1101: if(next_bit) state <= 4'b1110;  // bit 5
			4'b1110: if(next_bit) state <= 4'b1111;  // bit 6
			4'b1111: if(next_bit) state <= 4'b0001;  // bit 7
			4'b0001: if(next_bit) state <= 4'b0000;  // stop bit
			default: state <= 4'b0000;
		endcase

always @(posedge clk)
	if(Baud8Tick && next_bit && state[3]) RxD_data <= {~RxD_bit_inv, RxD_data[7:1]};

reg RxD_data_error;

always @(posedge clk) begin
	RxD_data_ready <= (Baud8Tick && next_bit && state==4'b0001 && ~RxD_bit_inv); 
	RxD_data_error <= (Baud8Tick && next_bit && state==4'b0001 &&  RxD_bit_inv);  
end

reg [4:0] gap_count;
always @(posedge clk) 
	if (state!=0) gap_count<=5'h00; 
		else if(Baud8Tick & ~gap_count[4]) gap_count <= gap_count + 5'h01;

assign RxD_idle = gap_count[4];


always @(posedge clk) 
	RxD_endofpacket <= Baud8Tick & (gap_count==5'h0F);

endmodule
