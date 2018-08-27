`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Hasan UNLU
// 
// Create Date:    13:40:08 04/23/2013 
// Design Name: 
// Module Name:    CPU 
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
module CPU(input clk,
			  input reset,
			  input RxD,
			  output TxD,			  
			  input [7:0] sw,
			  output reg [7:0] led,
			  output [6:0] seg,
			  output [3:0] an
			  );

//Memory links
	reg   [11:0] address;
	reg   [31:0] datain;
	wire  [31:0] dataout;
	reg   we;
	
//State machine regs
	reg [5:0] state;
	reg [5:0] state1;
	
	
//CPU regs
	reg [11:0] PC;
	reg [11:0] A;
	reg [11:0] B;
	reg [31:0] tempA;
	reg [31:0] tempB;
	reg [3:0] opcode;
	
//Uart signals
	wire data_ready;
	wire [7:0] Rx_Data;
	reg [7:0] Tx_Data;
	reg Tx_Start;
	wire Tx_Busy;
	

//temp regs
	reg [2:0] count;
	reg [15:0] segment_data;

	mem mem1(clk, datain, dataout, we, address);
	uart_rc uart_rc1(.clk(clk), .RxD(RxD), .RxD_data(Rx_Data), .RxD_data_ready(data_ready), .RxD_endofpacket());
	uart_tx uart_tx1(.clk(clk), .TxD_start(Tx_Start), .TxD_data(Tx_Data), .TxD(TxD), .TxD_busy(Tx_Busy));
	
	sevensegment my7segment(clk, segment_data, seg, an);

	always @(posedge clk) begin 
		if (reset==1) begin 
			state<=0;
			PC<=0;
			address<=0;
			count<=0;
			datain<=0;
			Tx_Start<=0;
		end else begin 
			case(state)
					0: begin
						if(data_ready)
							if(Rx_Data==8'h55) begin
								state<=1;
							end
						led<=Rx_Data;
						segment_data<={4'h1, 4'hd, 4'h2, 4'he};
					end
					1: begin
						segment_data<={4'h8, 4'h7, 4'h0, 4'h9};
						we<=0;
						if(count==2) begin
							count<=0;
							state<=2;
					   end else begin
							 if(data_ready) begin
								count<=count+1;
								address<={address[3:0],Rx_Data};
							 end
						  end
					end
					2: begin
						if(address==12'hfff) begin
							state<=3;
						end
						if(count==4) begin
							count<=0;
							we<=1;
							state<=1;
						end else begin
							 if(data_ready) begin
								we<=0;
								count<=count+1;
								datain<={datain[23:0],Rx_Data};
								led<=datain[7:0];
							 end
						  end
						PC<=0;
					end
					3: begin
						segment_data<={4'h7, 4'h6, 4'h5, 4'h4};
						we<=0;
						address<=PC;
						state<=4;
					end
					4: begin
						state<=5;
					end			
					5: begin
						if(dataout==32'h00000000) begin
							state<=8;
						end else begin
							opcode<=dataout[31:28];
							A<=dataout[25:14];
							B<=dataout[11:0];
							state<=6;
							state1<=0;
						end
					end
					6: begin
						case(opcode)
							0: begin //ADD *A <- (*A) + (*B)
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										address<=B;
										state1<=2;
									end
									2: begin 
									   address<=A;
										tempA<=dataout;	
										state1<=3;
									end
									3: begin									
										datain<=dataout+tempA;
										state1<=4;
										we<=1;
									end
									4: begin									
										state1<=5;									
									end
									5: begin
										state<=7;
									end
								endcase
							end 
							1: begin  //ADDi *A <- (*A) + B
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										state1<=2;
									end
									2: begin 
									   address<=A;
										datain<=dataout+B;
										we<=1;
										state1<=3;
									end
									3: begin						
										state1<=4;
									end
									4: begin									
										state<=7;									
									end
								endcase
							end 
							2: begin	//NAND  -> bitwise NAND *A <- ~((*A) & (*B))
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										address<=B;
										state1<=2;
									end
									2: begin 
									   address<=A;
										tempA<=dataout;	
										state1<=3;
									end
									3: begin									
										datain<=~(dataout & tempA);
										state1<=4;
										we<=1;
									end
									4: begin									
										state1<=5;									
									end
									5: begin
										state<=7;
									end
								endcase
							end 
							3: begin //NANDi -> bitwise NAND immediate *A <- ~((*A) & B)
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										state1<=2;
									end
									2: begin 
									   address<=A;
										datain<=~(dataout & B);
										we<=1;
										state1<=3;
									end
									3: begin						
										state1<=4;
									end
									4: begin									
										state<=7;									
									end
								endcase							
							end 
							4: begin //SRL   -> Shift Right if the shift amount (*B) is less than 32, otherwise Shift Left
										//*A <- ((*B) < 32) ? ((*A) >> (*B)) : ((*A) << ((*B) - 32))
								case(state1)
									0: begin
										address<=B;
										state1<=1;
									end
									1: begin 
										address<=A;
										state1<=2;
									end
									2: begin 
									   address<=A;
										tempB<=dataout;
										state1<=3;
									end
									3: begin
										if(tempB<32) begin
											datain<=(dataout >> tempB);
										end else begin
											datain<=(dataout << (tempB-32));
										end
										state1<=4;
										we<=1;
									end
									4: begin									
										state1<=5;									
									end
									5: begin
										state<=7;
									end
								endcase							
							end 						
							5: begin	//SRLi  -> Shift Right if the shift amount (B) is less than 32, otherwise Shift Left
										//*A <- (B < 32) ? ((*A) >> B) : ((*A) << (B - 32))
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										state1<=2;
									end
									2: begin
										if(B<32) begin
											datain<=(dataout >> B);
										end else begin
											datain<=(dataout << (B-32));
										end									
										we<=1;
										state1<=3;
									end
									3: begin						
										state1<=4;
									end
									4: begin									
										state<=7;									
									end
								endcase										
							
							end 
							6: begin //LT    -> if *A is Less Than *B then *A is set to 1, otherwise to 0.
										//*A <- *A < *B
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										address<=B;
										state1<=2;
									end
									2: begin 
									   address<=A;
										tempA<=dataout;	
										state1<=3;
									end
									3: begin
										if(tempA<dataout)
											datain<=1;
										else
											datain<=0;
										state1<=4;
										we<=1;
									end
									4: begin									
										state1<=5;									
									end
									5: begin
										state<=7;
									end
								endcase							
							
							end 						
							7: begin //LTi   -> if *A is Less Than B then *A is set to 1, otherwise to 0.
										//*A <- *A < B
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										state1<=2;
									end
									2: begin
										if(dataout < B)
											datain<=1;
										else
											datain<=0;								
										we<=1;
										state1<=3;
									end
									3: begin						
										state1<=4;
									end
									4: begin									
										state<=7;									
									end
								endcase										
							end 
							8: begin	//CP    -> Copy *B to *A
										//*A <- *B
								case(state1)
									0: begin
										address<=B;
										state1<=1;
									end
									1: begin 
										address<=A;
										state1<=2;
									end
									2: begin 
										datain<=dataout;
										we<=1;
										state1<=3;
									end
									3: begin									
										state1<=4;
									end
									4: begin									
										state<=7;									
									end
								endcase							
							end 						
							9: begin //CPi   -> Copy B to *A
										//       *A <- B
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										we<=1;
										datain<=B;
										state1<=2;
									end
									2: begin 
										state1<=3;
									end
									3: begin									
										state<=7;
									end
								endcase										
							end 
							10: begin
							/*CPI   -> (regular) Copy Indirect: Copy **B to *A
         (go to address B and fetch the number then treat it as an address and go to that address and get that data and write to address A)
         *A <- **B
         writeToAddress_A ( readFromAddress ( readFromAddress(B) ) )*/
								case(state1)
									0: begin
										address<=B;
										state1<=1;
									end
									1: begin 
										state1<=2;
									end
									2: begin 
									   address<=dataout;	
										state1<=3;
									end
									3: begin									
										state1<=4;
									end
									4: begin
										address<=A;
										datain<=dataout;
										we<=1;
										state1<=5;									
									end
									5: begin
										state<=7;
									end
								endcase
							end
							11: begin/*CPIi  -> (immediate) Copy Indirect: Copy *B to **A
         (go to address B and fetch the number (*B) then go to address A and fetch the number there and treat it as an address and write there *B)
         **A <- *B
         writeToAddress_(readFromAddress(A)) ( readFromAddress(B) )*/
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin
										address<=B;
										state1<=2;
									end
									2: begin 
									   address<=dataout;	
										state1<=3;
									end
									3: begin
										datain<=dataout;
										we<=1;
										state1<=4;
									end
									4: begin
										state1<=5;									
									end
									5: begin
										state<=7;
									end
								endcase
							end 
							12: begin
							/*BZJ   -> Branch on Zero
         (Branch to *A if *B is Zero, otherwise increment Program Counter (PC))
         PC <- (*B == 0) ? (*A) : (PC+1)
         if(*B == 0) goTo(*A), else goTo(nextInstruction)*/
								case(state1)
									0: begin
										address<=B;
										state1<=1;
									end
									1: begin 
										address<=A;
										state1<=2;
									end
									2: begin 
									   tempB<=dataout;
										state1<=3;
									end
									3: begin
										if(tempB==0) begin
											PC<=dataout[11:0];
											state<=3;
										end else begin
											state<=7;
										end
									end
								endcase				
							end 						
							13: begin	/*BZJi  -> Jump (unconditional branch)
											PC <- (*A) + B
											*/
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										state1<=2;
									end
									2: begin 
									   PC<=dataout+B;
										state<=3;
									end
								endcase									
							end 
							14: begin/*
											MUL   -> unsigned Multiply
											*A <- (*A) * (*B)
											writeToAddress_A ( readFromAddress(A) + readAddress(B) ) */
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										address<=B;
										state1<=2;
									end
									2: begin 
									   address<=A;
										tempA<=dataout;	
										state1<=3;
									end
									3: begin									
										datain<=dataout*tempA;
										state1<=4;
										we<=1;
									end
									4: begin									
										state1<=5;									
									end
									5: begin
										state<=7;
									end
								endcase
							end 						
							15: begin	/*MULi  -> unsigned Multiply
													*A <- (*A) * B
												writeToAddress_A ( readFromAddress(A) + B )	*/
								case(state1)
									0: begin
										address<=A;
										state1<=1;
									end
									1: begin 
										state1<=2;
									end
									2: begin 
									   address<=A;
										datain<=dataout*B;
										we<=1;
										state1<=3;
									end
									3: begin						
										state1<=4;
									end
									4: begin									
										state<=7;									
									end
								endcase							
							end 							
						endcase
					end
					7: begin 		
						PC<=PC+1;
						we<=0;
						state<=3;
					end
					
					//Read Cycle
					8: begin
						segment_data<={4'h3, 4'ha, 4'h2, 4'hf};
						count<=0;
						we<=0;
						state1<=0;
						if(data_ready)
							if(Rx_Data==8'h55)
								state<=9;
						led<=Rx_Data;
					end
					9: begin
						segment_data<={4'h7, 4'he, 4'ha, 4'hd};
						if(count==4) begin
							count<=0;
							state<=10;
							Tx_Start<=0;
							address<=tempA[27:16];
							tempB<={16'h0000, tempA[15:0]};
					   end else begin
							 if(data_ready) begin
								count<=count+1;
								tempA<={tempA[23:0],Rx_Data};
							 end
						  end
					end

					10: begin
	
/*					case(sw[1:0])
					3: led<=tempA[31:24];
					2: led<=tempA[23:16];
					1: led<=tempA[15:8];
					0: led<=tempA[7:0];
					endcase*/
					
						if(tempB==0)
							state<=14;
						else begin 
							state<=11;
							address<=address+1;
							tempB<=tempB-1;
						end
					end

					11: begin
						tempA<=dataout;
						state<=12;
					end					
					12: begin
						
						case(state1)
							0: begin 
									if(count==4) begin
										state<=10;
										count<=0;
										Tx_Start<=0;
									end else begin
										Tx_Start<=1;
										Tx_Data<=tempA[31:24];
										tempA<={tempA[23:0],8'h00};
										state1<=1;	
									end
							end
							1: begin 
									Tx_Start<=0;
									state1<=2;
							end
							2: begin 
									state1<=3;
							end
							3: begin
									if(Tx_Busy==0) begin
										state1<=0;
										count<=count+1;
									end
							end
						endcase					
					end					
					14: begin 
						
					end	
			endcase
		end
	end


endmodule
