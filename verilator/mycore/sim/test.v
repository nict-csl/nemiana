`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/13 17:25:13
// Design Name: 
// Module Name: test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module test1 (
	                    input 	clock,
	                    input 	reset,
	                    input [7:0] in1,
	                    input 	in2,
			    input 	in3);


   reg 					r1;

   reg 					r2;


      always @(posedge clock or posedge reset) begin
	       if(reset) begin
		  r1 = 0;

	       end

	       else if(in1 == 3)  begin
		  r1 = r2;

	       end
	       else if(in1 == 5)  begin
		  r1 = 1;

	       end
	       else begin
		  r1 = ~r2;

	       end
      end // always @ (posedge clock or posedge reset)

      always @(posedge clock or posedge reset) begin
	       if(reset) begin
		  r2 = 0;

	       end

	       else if(in2)  begin
		  r2 = r1;

	       end
	       else if(in3)   begin
		  r2 = 1;

	       end
	       else begin
		  r2 = ~r1;

	       end
      end // always @ (posedge clock or posedge reset)

endmodule // test1


