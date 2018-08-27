`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:23:01 03/24/2013 
// Design Name: 
// Module Name:    sevensegment 
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
module sevensegment(
	input clk,
	input  [15:0] data,
	output reg [6:0] seg,
	output reg [3:0] an	
   );

	reg [26:0] counter; 
	reg clk_50Hz;
	reg [2:0] state=0;
	reg [3:0] out;	
	
	always @(posedge clk) begin
		if(counter>=250000) begin
			counter<=0;
			clk_50Hz<=1;
		end else begin
						counter<=counter+1;
						clk_50Hz<=0;
					end
	end

	always @(*) begin
		case(state)
			0: begin 
					out=data[3:0];
					an=4'b1110;
				end
			1: begin
					out=data[7:4];
					an=4'b1101;
				end
			2: begin
					out=data[11:8];				
					an=4'b1011;
				end
			3: begin
					out=data[15:12];
					an=4'b0111;
				end
		endcase
		case(out)
			0: seg= 7'b1000000; //O
			1: seg= 7'b1111001; //I
			2: seg= 7'b1000111; //L
			3: seg= 7'b0001001; //H
			4: seg= 7'b0111111; //-
			5: seg= 7'b0101011; //n
			6: seg= 7'b0000001; //U
			7: seg= 7'b0101111; //r
			8: seg= 7'b0001100; //P
			9: seg= 7'b0010000; //g
			10: seg=7'b0001000;
			11: seg=7'b0000011;
			12: seg=7'b1000110;			
			13: seg=7'b0100001;
			14: seg=7'b0000110;
			15: seg=7'b0000111; //t
		endcase	
	end		
	
	
	always @(posedge clk_50Hz) begin
		case(state)
			0: begin
				state<=1;

			end
			1: begin
				state<=2;
		
			end
			2: begin
				state<=3;
			
			end
			3: begin
				state<=0;
			
			end
		endcase
	end
	


	
endmodule
