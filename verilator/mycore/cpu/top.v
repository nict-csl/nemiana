`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/08 17:00:46
// Design Name: 
// Module Name: top
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

// J9
// K9
// K8
// L8
// L10
// M10
// M8
// M9

module top(
	   output [11:0] led,
	   output wire 	 uart_tx,
	   input wire 	 uart_rx
    );

   wire 		 clock;
   wire 		 clock2;

   wire 		 nreset; 

   wire [31:0] 	gpio0;
   wire [31:0] 	gpio1;
   wire 	fifo_reset = gpio0[9];


   wire [31:0] 	m_tdata;
   wire [3:0] 	m_tkeep;
   wire 	m_tlast;
   wire 	m_tready;
   wire 	m_tvalid
;
   wire [127:0] dma_ctrl_dma_in;
   reg 		dma_ctrl_dma_we;
   wire 	dma_ctrl_dma_start = gpio0[8];
   wire [11:0] 	dma_ctrl_led;
   wire 	dma_ctrl_dma_writable;
   
   dma_ctrl dma_ctl(
   		    .pl_clk(clock),
		    .cpu_clk(clock2),
   		    .nreset(nreset),
		    .fifo_reset(fifo_reset),
		    .dma_start(dma_ctrl_dma_start),
   		    .led(dma_ctrl_led),
   		    .m_tdata(m_tdata),
   		    .m_tkeep(m_tkeep),
   		    .m_tlast(m_tlast),
   		    .m_tready(m_tready),
   		    .m_tvalid(m_tvalid),
		    .dma_in(dma_ctrl_dma_in),
		    .dma_we(dma_ctrl_dma_we),
		    .dma_writable(dma_ctrl_dma_writable)
   		    );

   wire [31:0] 	s_tdata;
   wire [3:0] 	s_tkeep;
   wire 	s_tlast;
   wire 	s_tready;
   wire 	s_tvalid;
   wire [63:0]  dma_trans_dma_out;
   wire 	dma_trans_dma_re = gpio0[15];
   wire 	xxxx = gpio0[16];
   wire 	dma_trans_dma_r_enable;
   wire [11:0]  dma_trans_led;

   dma_trans dma_trans(
   		       .pl_clk(clock),
   		       .cpu_clk(clock2),
   		       .nreset(nreset),
   		       .fifo_reset(fifo_reset),
   		       .led(dma_trans_led),
   		       .s_tdata(s_tdata),
   		       .s_tkeep(s_tkeep),
   		       .s_tlast(s_tlast),
   		       .s_tready(s_tready),
   		       .s_tvalid(s_tvalid),
   		       .dma_out(dma_trans_dma_out),
   		       .dma_re(dma_trans_dma_re),
		       .xxxx(xxxx),
   		       .dma_r_enable(dma_trans_dma_r_enable)
   		    );

   dma_main_wrapper dma_main(
			     .M_AXIS_MM2S_0_tdata(s_tdata),
			     .M_AXIS_MM2S_0_tkeep(s_tkeep),
			     .M_AXIS_MM2S_0_tlast(s_tlast),
			     .M_AXIS_MM2S_0_tready(s_tready),
			     .M_AXIS_MM2S_0_tvalid(s_tvalid),
			     .S_AXIS_S2MM_0_tdata(m_tdata),
			     .S_AXIS_S2MM_0_tkeep(m_tkeep),
			     .S_AXIS_S2MM_0_tlast(m_tlast),
			     .S_AXIS_S2MM_0_tready(m_tready),
			     .S_AXIS_S2MM_0_tvalid(m_tvalid),
			     .gpio_io_i_0(gpio1),
			     .gpio_io_o_0(gpio0),
			     .clk(clock),
			     .clk2(clock2),
			     .nreset(nreset)
			     );

   

   
   wire 	cpu_clk;
   wire 	cpu_rst;
   wire [31:0] 	cpu_gpi_in;
   wire [31:0] 	cpu_gpo_out;
   wire [31:0] 	cpu_gpi1_in;
   wire [31:0] 	cpu_gpo1_out;
   wire [31:0] 	cpu_write_addr;
   wire [31:0] 	cpu_write_data;
   wire [31:0] 	cpu_gpi_ctrl_in;
   wire [127:0] cpu_iana_out;
   wire 	cpu_iana_we;
   wire 	cpu_stall_enable_in;
   wire 	cpu_stall_disable_in;
   wire 	cpu_is_stall_enabled_out;
   wire 	cpu_uart_tx;
   wire 	cpu_uart_rx;
   wire [3:0] 	cpu_led;

   cpu_top cpu(
	       .clk(cpu_clk),
    	       .gpi_in(cpu_gpi_in),
    	       .gpo_out(cpu_gpo_out),
    	       .gpi1_in(cpu_gpi1_in),
    	       .gpo1_out(cpu_gpo1_out),
	       .cpu_write_addr_in(cpu_write_addr),
	       .cpu_write_data_in(cpu_write_data),
	       .cpu_write_enable_in(dma_trans_dma_r_enable),
    	       .cpu_ctrl_in(cpu_gpi_ctrl_in),
	       .iana_out(cpu_iana_out),
	       .stall_enable_in(cpu_stall_enable_in),
	       .stall_disable_in(cpu_stall_disable_in),
	       .is_stall_enabled_out(cpu_is_stall_enabled_out),
    	       .uart_tx(cpu_uart_tx),
    	       .uart_rx(cpu_uart_rx),
    	       .led(cpu_led)
	       );
   
   assign cpu_clk=clock2;
   assign cpu_rst=nreset;
   assign cpu_gpi_in=0;
   assign cpu_gpi1_in=0;
   assign cpu_gpi3_in=0; //メモリに書き込むデータ
   assign cpu_gpi4_in=0; //メモリアドレス
   assign cpu_write_addr = dma_trans_dma_out[63:32];
   assign cpu_write_data = dma_trans_dma_out[31:0];
   assign cpu_gpi_ctrl_in = gpio0;

   assign dma_ctrl_dma_in = cpu_iana_out;
   assign uart_tx = cpu_uart_tx;
   assign uart_rx = cpu_uart_rx;
   assign led     = {cpu_led[0], cpu_led[2], dma_trans_led[9:0]};
//   assign gpio1   = {dma_trans_led, dma_ctrl_led[5:4], cpu_led};
   assign gpio1   = {dma_ctrl_led, dma_ctrl_led[5:4], cpu_led};
   reg prev_dma_ctrl_dma_we;
   reg prev_dma_ctrl_dma_we2;
   reg prev_dma_ctrl_dma_we3;
   always @(posedge clock2 or negedge nreset) begin
      if(!nreset) begin
	 prev_dma_ctrl_dma_we <= 0;
	 prev_dma_ctrl_dma_we2 <= 0;
	 prev_dma_ctrl_dma_we3 <= 0;
	 dma_ctrl_dma_we <= 0;
      end
      else begin
	 prev_dma_ctrl_dma_we   <= !cpu_is_stall_enabled_out;
	 prev_dma_ctrl_dma_we2  <= prev_dma_ctrl_dma_we ;
	 prev_dma_ctrl_dma_we3  <= prev_dma_ctrl_dma_we2 ;
	 dma_ctrl_dma_we <= (prev_dma_ctrl_dma_we3 & (!cpu_gpi_ctrl_in[0])) | (!cpu_is_stall_enabled_out);
      end
   end
   // CPUの中で作っていないので，外側で調整作る必要がある．
   assign cpu_stall_enable_in = (!dma_ctrl_dma_writable) && (cpu_gpi_ctrl_in[13]);
   assign cpu_stall_disable_in = cpu_gpi_ctrl_in[14];

endmodule // top

