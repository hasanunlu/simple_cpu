`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:40:31 04/23/2013 
// Design Name: 
// Module Name:    mem 
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
module mem( input clk,
				input [31:0] datain,
				output reg [31:0] dataout,
				input we,
				input [11:0] address
    );

	reg [31:0] memory [0:4095];
	
	always @(posedge clk) begin
		if(we)
			memory[address]<=datain;
		else
			dataout<=memory[address];
	end

endmodule
