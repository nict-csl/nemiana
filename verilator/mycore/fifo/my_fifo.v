`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/06 09:23:27
// Design Name: 
// Module Name: fifo
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

/* 非同期FIFO */

module my_fifo #(parameter WA=8,WD=32)
   (input  rst         // reset
    ,input  wclk        // write clock
    ,input  wen         // write enable
    ,input[WD-1:0] wdat // write data
    ,output reg wfull   // write full
    ,input  rclk        // read clock
    ,input  ren         // read enable
    ,output reg[WD-1:0] rdat   // read data
    ,output reg rempty  // read empty
    );
   reg [WA:0] wadr_reg;
   reg [WA:0] radr_reg;
   reg [WA:0] wptr_reg,wptr0_reg,wptr1_reg;
   reg [WA:0] rptr_reg,rptr0_reg,rptr1_reg;
   wire [WA:0] next_wadr,next_wptr;
   wire [WA:0] next_radr,next_rptr;
   reg [WD-1:0] ram[0:2**WA-1];
   /************************************************************
    * DPM
    * 
    *  ***********************************************************/
   always @(posedge wclk)
     if(wen) ram[wadr_reg[WA-1:0]] <= wdat;
   /* Show-ahead mode / First-word Fall-through mode */
   always @(posedge rclk)
     rdat <= ram[radr_reg[WA-1:0]+(ren? 1'b1:1'b0)];
//   always @(posedge rclk)
//     if(ren) rdat <= ram[radr_reg[WA-1:0]];
   /************************************************************
    * wclk domain
    * 
    *  ***********************************************************/
   /* write address */

   always @(posedge wclk or posedge rst)
     begin
	if(rst)
	  {wadr_reg,wptr_reg} <= {{(WA+1){1'b0}},{(WA+1){1'b0}}};
	else if(wen)
	  {wadr_reg,wptr_reg} <= {next_wadr,next_wptr};
     end // always @ (posedge wclk or posedge rst)
   assign next_wadr = wadr_reg + (wen & ~wfull);
   // binary
   assign next_wptr = next_wadr ^ (next_wadr>>1'b1);
   // gray

   /* cdc transfer of rptr */
   always @(posedge wclk or posedge rst)
     begin
	if(rst)
	  {rptr1_reg,rptr0_reg} <= {{(WA+1){1'b0}},{(WA+1){1'b0}}};
	else
	  {rptr1_reg,rptr0_reg} <= {rptr0_reg,rptr_reg};
     end // always @ (posedge wclk or posedge rst)

   /* full flag */
   always @(posedge wclk or posedge rst)
     begin
	if(rst)
	  wfull <= 1'b0;
	else if(next_wptr=={~rptr1_reg[WA:WA-1],rptr1_reg[WA-2:0]})
	  wfull <= 1'b1;
	else
	  wfull <= 1'b0;
     end // always @ (posedge wclk or posedge rst)

   /************************************************************
    * rclk domain
    * 
    *  ***********************************************************/
   /* read address */

   always @(posedge rclk or posedge rst)
     begin
	if(rst)
	  {radr_reg,rptr_reg} <= {{(WA+1){1'b0}},{(WA+1){1'b0}}};
	else if(ren)
	  {radr_reg,rptr_reg} <= {next_radr,next_rptr};
     end // always @ (posedge rclk or posedge rst)
   assign next_radr = radr_reg + (ren & ~rempty);
   // binary
   assign next_rptr = next_radr ^ (next_radr >> 1);
   // gray
   /* cdc transfer of wptr */
   always @(posedge rclk or posedge rst)
     begin
	if(rst)
	  {wptr1_reg,wptr0_reg} <= {{(WA+1){1'b0}},{(WA+1){1'b0}}};
	else
	  {wptr1_reg,wptr0_reg} <= {wptr0_reg,wptr_reg};
     end // always @ (posedge rclk or posedge rst)
   /* empty flag */

   always @(posedge rclk or posedge rst)
     begin
	if(rst)
	  rempty <= 1'b1;
	else if(next_rptr==wptr1_reg)
	  rempty <= 1'b1;
	else
	  rempty <= 1'b0;
     end // always @ (posedge rclk or posedge rst)
endmodule
