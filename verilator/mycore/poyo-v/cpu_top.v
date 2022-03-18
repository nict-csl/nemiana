//
// cpu_top
//


`include "define.vh"

module cpu_top (
    input wire 		clk,
    input wire [31:0] 	gpi_in,
    output wire [31:0] 	gpo_out,
    input wire [31:0] 	gpi1_in,
    output wire [31:0] 	gpo1_out,
    input wire [31:0] 	cpu_write_addr_in, //メモリに書き込むデータ
    input wire [31:0] 	cpu_write_data_in, //メモリアドレス
    input wire 		cpu_write_enable_in, //書き込みが有効か？
		
    input wire [31:0] 	cpu_ctrl_in,
    output wire [127:0] iana_out,
    input wire 		stall_enable_in,
    input wire 		stall_disable_in, 
    output wire 	is_stall_enabled_out,
    output wire 	uart_tx,
    input wire 		uart_rx,
    output wire [3:0] 	led
		
);
   reg [31:0] 		iana_1_pc;
   reg [31:0] 		iana_2_pc;
   reg [31:0] 	       iana_3_pc;
   reg [31:0] 	       iana_1_inst;
   reg [31:0] 	       iana_2_inst;
   reg [31:0] 	       iana_3_inst;
   reg [31:0] 	       iana_2_src1;
   reg [31:0] 	       iana_2_src2;
   reg [31:0] 	       iana_3_src1;
   reg [31:0] 	       iana_3_src2;
   reg [31:0] 	       iana_2_dest;
   reg [31:0] 	       iana_3_dest;
   reg [31:0] 	       iana_1_attr;
   reg [31:0] 	       iana_2_attr;
   reg [31:0] 	       iana_3_attr;
   reg [31:0] 	       iana_counter;

   reg 		       stall_flag;
   wire		       prev_stall_flag;
   wire 	       is_stall_requested_from_instruction;
   wire 	       is_resume_requested;
   
   reg [31:0] 	       restore_mem[0:31] ;
   reg  	       restore_state;
   wire [4:0] 	       restore_regnum;
   wire [31:0] 	       restore_reg_value;
   reg [31:0] 	       restore_pc;
   wire 	       restore_dmem_enable;
   wire 	       restore_reg_enable;
   wire 	       restore_pc_enable;
   
   wire [31:0] 	       dmem_addr_real;
   wire [3:0] 	       restore_dmem_we;
   wire [3:0] 	       dmem_we_real;
   wire [7:0] 	       dmem_data_real[3:0];
   
   reg [31:0] 	       gpi_in_reg;
   reg [31:0] 	       gpo_out_reg;
   reg [31:0] 	       gpi1_in_reg;
   reg [31:0] 	       gpo1_out_reg;
   reg [31:0] 	       cpu_write_addr_in_reg;
   reg [31:0] 	       cpu_write_data_in_reg;
   reg [31:0] 	       cpu_ctrl_in_reg;

   wire 	       rst_n = ~cpu_ctrl_in_reg[0];
   wire                restore_state_flag = cpu_ctrl_in_reg[1];
   //wire 	       register_write_flag = cpu_ctrl_in_reg[2];
   //wire 	       pc_write_flag=cpu_ctrl_in_reg[3];
   //wire 	       restore_dmem_enable_flag = cpu_ctrl_in_reg[4];
   //wire 	       restore_dmem_we_flag = cpu_ctrl_in_reg[5];

   //Fifoのenableを確認する必要がある．
   wire 	       register_write_flag = cpu_write_addr_in_reg[31] & cpu_write_enable_in;
   assign restore_regnum  = cpu_write_addr_in_reg[4:0];
   assign restore_reg_value  = cpu_write_data_in_reg[31:0];
   wire 	       pc_write_flag = cpu_write_addr_in_reg[30]  & cpu_write_enable_in;
   wire 	       restore_dmem_enable_flag = cpu_write_addr_in_reg[29] & cpu_write_enable_in;
   wire 	       restore_dmem_we_flag = cpu_write_addr_in_reg[29]  & cpu_write_enable_in;
//   assign restore_reg_enable = (restore_state & cpu_ctrl_in_reg[6]);
   assign restore_reg_enable = restore_state & register_write_flag;
   assign restore_pc_enable = cpu_ctrl_in_reg[7];
   
   wire [31:0] 	       cpu_write_addr       = {4'd0 , cpu_write_addr_in_reg[27:0]};
   assign is_resume_requested = cpu_ctrl_in_reg[12];
   wire 	       is_stall_requested_from_outer = cpu_ctrl_in_reg[11];
   wire 	       is_trace_stall_requested = cpu_ctrl_in_reg[13]; //ここでは使っていない外部で使う
   reg 		       stall_mode_enabled;

   // 各々の信号の立ち下がりを検出して，そのORをresume_flagとする．
   // 単なるORだと，どちらかがずーと１だとresumeしない．
   // ANDだと，両方が１になるまでResumeしなくなる．
   reg 		       prev_resume_requested1;
   reg 		       prev_resume_requested2;
   always @(posedge clk) begin
      prev_resume_requested1 = is_resume_requested;
      prev_resume_requested2 = stall_disable_in;
   end
   wire resume_flag1 = prev_resume_requested1 && (!is_resume_requested);
   wire resume_flag2 = prev_resume_requested2 && (!stall_disable_in);
   wire resume_flag = resume_flag1 | resume_flag2;
   
   wire stall_mode_flag = is_stall_requested_from_outer | is_stall_requested_from_instruction| stall_enable_in;

   assign is_stall_enabled_out = stall_flag;
   
   always @(posedge clk or negedge rst_n) begin
      if(rst_n==1'b0) begin
	 stall_mode_enabled <=0;
      end
      else if(stall_mode_flag) begin
	 stall_mode_enabled <=1;
      end
      else if(stall_mode_enabled && resume_flag) begin
	 // 要求の立ち下がりにする．
	 stall_mode_enabled <=0;
      end
   end

   assign prev_stall_flag = stall_mode_enabled;
   
   always @(posedge clk or negedge rst_n) begin
      if(rst_n==1'b0) begin
	 stall_flag <= 0;
      end
      else begin
	 stall_flag <= prev_stall_flag;
      end
   end

   reg 	iana_stall_requested_from_instruction;
   always @(posedge clk or negedge rst_n) begin
      if(rst_n==1'b0) begin
	 iana_stall_requested_from_instruction <= 0;

      end
      else if(is_stall_requested_from_instruction) begin
	 iana_stall_requested_from_instruction <= 1;
      end
      else if(resume_flag) begin
	 iana_stall_requested_from_instruction <= 0;
      end
   end

   always @(posedge clk) begin
      gpi_in_reg = gpi_in;
      gpi1_in_reg = gpi1_in;
      cpu_write_addr_in_reg = cpu_write_addr_in;
      cpu_write_data_in_reg = cpu_write_data_in;
      cpu_ctrl_in_reg = cpu_ctrl_in;
   end

   assign gpo_out = gpo_out_reg;
   assign gpo1_out = gpo1_out_reg;
    // reset

    // PC
    wire [31:0] next_PC;
    wire [31:0] ex_br_addr;
    wire ex_br_taken;
    reg [31:0] PC;


    // fetch stage
   wire [31:0] imem_addr;
   wire [31:0] imem_rd_data;
   
    // execution stage
    reg [31:0] ex_PC;
    
    // decoder
    wire [31:0] decoder_insn;
    wire [4:0] decoder_srcreg1_num, decoder_srcreg2_num, ex_dstreg_num;
    wire [31:0] decoder_imm;
    wire [5:0] ex_alucode;
    wire [1:0] ex_aluop1_type, ex_aluop2_type;
    wire ex_reg_we, ex_is_load, ex_is_store;
    wire  ex_is_ecall;
   
    // register file
    wire regfile_we;
    wire [4:0] regfile_srcreg1_num, regfile_srcreg2_num, regfile_dstreg_num;
    wire [31:0] regfile_srcreg1_value, regfile_srcreg2_value, regfile_dstreg_value;

    // ALU
    wire [5:0] alu_alucode;
    wire [31:0] alu_op1, alu_op2, ex_alu_result;
    
    wire [31:0] ex_srcreg1_value, ex_srcreg2_value, ex_store_value;

    // dmem
    wire [3:0] dmem_we;
    wire [31:0] dmem_addr;
    wire [7:0] dmem_wr_data [3:0]; 
    wire [7:0] dmem_rd_data [3:0];

    // UART TX
    wire uart_we;
    wire [7:0] uart_data_in;
    wire uart_data_out;
    wire  uart_tx_status;

    // UART RX
    wire uart_rd_en;
    wire [7:0] uart_rd_data;
    wire [31:0] uart_value;
    wire [31:0] 	uart_tx_value;
    // GPIO
    wire [31:0] gpi_data_in;
    wire [31:0] gpi_data_out;
    wire [31:0] gpi_value;
    wire gpo_we;
    wire [31:0] gpo_data_in;
    wire [31:0] gpo_data_out;
    wire [31:0] gpo_value;
    // GPIO1
    wire [31:0] gpi1_data_in;
    wire [31:0] gpi1_data_out;
    wire [31:0] gpi1_value;
    wire gpo1_we;
    wire [31:0] gpo1_data_in;
    wire [31:0] gpo1_data_out;
    wire [31:0] gpo1_value;

    //
    wire [31:0] hc_value;

    // write-back stage
    reg wb_reg_we;
    reg [4:0] wb_dstreg_num;
    reg wb_is_load;
    reg [5:0] wb_alucode;
    reg [31:0] wb_alu_result;
    wire [31:0] wb_load_value, wb_dstreg_value;

    assign led[1] = PC[5];
   // assign led[2] = hc_value[1];
    
parameter CNT_1SEC = 27'd50_000_000;  // 100MHz clk for 1sec
reg [26:0] cnt;
reg onoff;

always @(posedge clk) begin
    if (cnt >= CNT_1SEC) begin
        cnt <= 27'd0;
        onoff <= ~onoff;
    end
    else begin
        cnt <= cnt + 1;
    end
end

   assign led[0] = iana_stall_requested_from_instruction;
   assign led[3] = cnt[20];
   assign led[2] = stall_flag;
      
    //====================================================================
    // program counter
    //====================================================================
    function [31:0]  nextpc(
			    input [31:0] pc,
			    input 	 rstn,
			    input 	 br_taken,
			    input [31:0] br_addr);
       begin
	  if(rstn==1'b0) begin
	     nextpc=PC + 32'd4;
	  end
	  else begin
	     if(br_taken) begin
		nextpc=br_addr  + 32'd4; //ジャンブした次のアドレスなので，+4している．
	     end
	     else begin
		nextpc=PC + 32'd4;
	     end
	  end
       end
       
    endfunction

   // ex stage
   assign next_PC = nextpc(PC, rst_n, ex_br_taken, ex_br_addr);

   reg [31:0] next_PC_prev;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
	 next_PC_prev <= next_PC;
      end
      else  if((prev_stall_flag) && (!stall_flag)) begin
  	 next_PC_prev <= next_PC;
      end
   end
   
   // これだとjump命令の時にstallするとうまく行かない
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
	 if (restore_pc_enable) begin
	    PC <= restore_pc;
	 end
	 else begin
	    PC <= `RESET_ADDR;
	 end
      end else begin
	 if(stall_flag) begin
            PC <= next_PC_prev;
	 end
	 else begin
	    PC <= next_PC;
	 end
      end
   end

    //====================================================================re
    // fetch stage
    //====================================================================
    // ex stage
    assign imem_addr = (rst_n == 1'b0) ? 32'd0 : ex_br_taken ? ex_br_addr : PC;

   reg [31:0] imem_addr_prev;
   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
	 imem_addr_prev <= imem_addr;
      end
      else if((prev_stall_flag) && (!stall_flag)) begin
	 imem_addr_prev <= imem_addr;
      end
   end

   wire [31:0] imem_addr_real = (rst_n == 1'b0) ? 32'd0 
	       : stall_flag ? imem_addr_prev : imem_addr;
   
    imem imem (
               .clk(clk),
               .addr(imem_addr_real),
               .rd_data(imem_rd_data)
    );

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ex_PC <= 32'd0;
        end else begin
            ex_PC <= imem_addr_real;
        end
    end

    //====================================================================
    // execution stage
    //====================================================================

    always @(posedge clk or negedge rst_n) begin
       if(!rst_n) begin
	  iana_1_pc   <= 32'hFFFFFFFF;
	  iana_2_pc   <= 32'hFFFFFFFF;
	  iana_2_inst <= 32'hFFFFFFFF;
	  iana_3_pc   <= 32'hFFFFFFFF;
	  iana_3_inst <= 32'hFFFFFFFF;
	  iana_1_attr <= 32'hFFFFFFFF;
       end
       else if(stall_flag) begin
	  iana_1_pc   <= imem_addr_real;
//	  iana_2_pc   <= iana_1_pc;
	  iana_2_pc   <= 32'hFFFFFFFF;
	  iana_2_inst <= `NOP_INST;
//	  iana_3_pc   <= iana_2_pc;
	  iana_3_pc   <= 32'hFFFFFFFF;
	  iana_3_inst <= iana_2_inst;
	  iana_1_attr <= 32'hFEDCBA98;
       end
       else begin
	  iana_1_pc   <= imem_addr_real;
	  iana_2_pc   <= iana_1_pc;
	  iana_2_inst <= imem_rd_data;
	  iana_3_pc   <= iana_2_pc;
	  iana_3_inst <= iana_2_inst;
	  iana_1_attr <= iana_counter;
       end
    end
   
    assign decoder_insn = stall_flag ? `NOP_INST : imem_rd_data;

    decoder decoder_0 (
        .insn(decoder_insn),
        .srcreg1_num(decoder_srcreg1_num),
        .srcreg2_num(decoder_srcreg2_num),
        .dstreg_num(ex_dstreg_num),
        .imm(decoder_imm),
        .alucode(ex_alucode),
        .aluop1_type(ex_aluop1_type),
        .aluop2_type(ex_aluop2_type),
        .reg_we(ex_reg_we),
        .is_load(ex_is_load),
        .is_store(ex_is_store),
		       .is_ecall(ex_is_ecall)
    );

    assign is_stall_requested_from_instruction = ex_is_ecall; // ecall命令によりstallが要求された

    assign regfile_srcreg1_num = decoder_srcreg1_num;
    assign regfile_srcreg2_num = decoder_srcreg2_num;

   wire [4:0] regfile_dstreg_num_real = restore_reg_enable?restore_regnum:regfile_dstreg_num;
   wire [31:0] regfile_dstreg_value_real = restore_reg_enable?restore_reg_value:regfile_dstreg_value;
   wire regfile_we_real =  restore_reg_enable | regfile_we;
    regfile regfile_0 (
        .clk(clk),
        .we(regfile_we_real),
        .srcreg1_num(regfile_srcreg1_num),
        .srcreg2_num(regfile_srcreg2_num),
        .dstreg_num(regfile_dstreg_num_real),
        .dstreg_value(regfile_dstreg_value_real),
        .srcreg1_value(regfile_srcreg1_value),
        .srcreg2_value(regfile_srcreg2_value)
    );


    // alu
    assign alu_alucode = ex_alucode;

    // wb stage
    assign ex_srcreg1_value = (regfile_srcreg1_num==5'd0) ? 32'd0 : 
                              (wb_reg_we && (decoder_srcreg1_num == wb_dstreg_num)) ? wb_dstreg_value : regfile_srcreg1_value;
    assign ex_srcreg2_value = (regfile_srcreg2_num==5'd0) ? 32'd0 : 
                              (wb_reg_we && (decoder_srcreg2_num == wb_dstreg_num)) ? wb_dstreg_value : regfile_srcreg2_value;

    assign alu_op1 = (ex_aluop1_type == `OP_TYPE_REG) ? ex_srcreg1_value :
                     (ex_aluop1_type == `OP_TYPE_IMM) ? decoder_imm :
                     (ex_aluop1_type == `OP_TYPE_PC) ? ex_PC: 32'd0;
    assign alu_op2 = (ex_aluop2_type == `OP_TYPE_REG) ? ex_srcreg2_value :
                     (ex_aluop2_type == `OP_TYPE_IMM) ? decoder_imm :
                     (ex_aluop2_type == `OP_TYPE_PC) ? ex_PC : 32'd0;

    alu alu_0 (
        .alucode(alu_alucode),
        .op1(alu_op1),
        .op2(alu_op2),
        .alu_result(ex_alu_result),
        .br_taken(ex_br_taken)
    );
    always @(posedge clk) begin
       iana_2_src1 <= ex_srcreg2_value;
       iana_2_src2 <= ex_srcreg2_value;
       iana_3_src1 <= iana_2_src1;
    end
    always @(posedge clk) begin
    end


   wire [6:0] 	       iana_src1_attr;
   wire [6:0] 	       iana_src2_attr;
   wire [4:0] 	       iana_dest_attr;
   wire  	       iana_br_taken;
   assign iana_br_taken  = ex_br_taken;
   assign iana_src1_attr = {(ex_aluop1_type == `OP_TYPE_PC), (ex_aluop1_type == `OP_TYPE_IMM), regfile_srcreg1_num};
   assign iana_src2_attr = {(ex_aluop2_type == `OP_TYPE_PC), (ex_aluop2_type == `OP_TYPE_IMM), regfile_srcreg2_num};

    assign ex_store_value = ((ex_alucode == `ALU_SW) || (ex_alucode == `ALU_SH) || (ex_alucode == `ALU_SB)) ? ex_srcreg2_value : 32'd0;

    assign ex_br_addr = (ex_alucode==`ALU_JAL) ? ex_PC + decoder_imm :
                        (ex_alucode==`ALU_JALR) ? alu_op1 + decoder_imm :
                        ((ex_alucode==`ALU_BEQ) || (ex_alucode==`ALU_BNE) || (ex_alucode==`ALU_BLT) ||
                         (ex_alucode==`ALU_BGE) || (ex_alucode==`ALU_BLTU) || (ex_alucode==`ALU_BGEU)) ? ex_PC + decoder_imm : 32'd0;

   wire iana_jump_flag =  (ex_alucode==`ALU_JAL)||(ex_alucode==`ALU_JALR)||(ex_alucode==`ALU_BEQ) ||
	(ex_alucode==`ALU_BNE) || (ex_alucode==`ALU_BLT) ||
        (ex_alucode==`ALU_BGE) || (ex_alucode==`ALU_BLTU) || (ex_alucode==`ALU_BGEU);
   
   // storeのとき，rs2が格納される値で
   // rs1+immが格納されるアドレス
   //  iana_2_destに格納アドレスが入る
   always @(posedge clk) begin
      if(iana_jump_flag) begin
	 iana_2_dest <= ex_br_addr;
      end
//      else if(ex_is_store) begin
//	 iana_2_dest <= ex_store_value;
//      end
      else begin
	 iana_2_dest <= ex_alu_result;
      end
   end
   assign iana_dest_attr = ex_dstreg_num;

   always @(posedge clk) begin
      iana_2_attr <= {iana_src1_attr, iana_src2_attr, iana_dest_attr, iana_jump_flag, ex_is_load, iana_br_taken, iana_1_attr[9:0]};
   end
   
    // store
    assign dmem_addr = ex_alu_result - `DMEM_START_ADDR;  //
   

    function [31:0] dmem_wr_data_sel(
        input is_store,
        input [5:0] alucode,
        input [1:0] alu_result,
        input [31:0] store_value
    );
        
        begin
            if (is_store) begin
                case (alucode)
                    `ALU_SW: dmem_wr_data_sel = store_value;
                    `ALU_SH: begin
                        case (alu_result)
                            2'b00: dmem_wr_data_sel = {16'd0, store_value[15:0]};
                            2'b01: dmem_wr_data_sel = {8'd0, store_value[15:0], 8'd0};
                            2'b10: dmem_wr_data_sel = {store_value[15:0], 16'd0};
                            default: dmem_wr_data_sel = {16'd0, store_value[15:0]};
			endcase
                    end
                    `ALU_SB: begin
                        case (alu_result)
                            2'b00: dmem_wr_data_sel = {24'd0, store_value[7:0]};
                            2'b01: dmem_wr_data_sel = {16'd0, store_value[7:0], 8'd0};
                            2'b10: dmem_wr_data_sel = {8'd0, store_value[7:0], 16'd0};
                            2'b11: dmem_wr_data_sel = {store_value[7:0], 24'd0};
                        endcase
                    end                    
                    default: dmem_wr_data_sel = store_value;
                endcase
            end else begin
                dmem_wr_data_sel = 32'd0;
            end
        end
        
    endfunction

    assign {dmem_wr_data[3], dmem_wr_data[2], dmem_wr_data[1], dmem_wr_data[0]} = dmem_wr_data_sel(ex_is_store, ex_alucode, ex_alu_result[1:0], ex_store_value);

    
    function [3:0] dmem_we_sel(
        input is_store,
        input [5:0] alucode,
        input [1:0] alu_result
    );
        
        begin
            if (is_store) begin
                case (alucode)
                    `ALU_SW: dmem_we_sel = 4'b1111;
                    `ALU_SH: begin
                        case (alu_result)
                            2'b00: dmem_we_sel = 4'b0011;
                            2'b01: dmem_we_sel = 4'b0110;
                            2'b10: dmem_we_sel = 4'b1100;
                            default: dmem_we_sel = 4'b0000;
                        endcase
                    end
                    `ALU_SB: begin
                        case (alu_result)
                            2'b00: dmem_we_sel = 4'b0001;
                            2'b01: dmem_we_sel = 4'b0010;
                            2'b10: dmem_we_sel = 4'b0100;
                            2'b11: dmem_we_sel = 4'b1000;
                        endcase
                    end                    
                    default: dmem_we_sel = 4'b0000;
                endcase
            end else begin
                dmem_we_sel = 4'b0000;
            end
        end
        
    endfunction

    //
    assign dmem_we = (dmem_addr <= `DMEM_SIZE) ? dmem_we_sel(ex_is_store, ex_alucode, ex_alu_result[1:0]) : 4'd0;

   assign restore_dmem_enable    = restore_state & restore_dmem_enable_flag;
   assign dmem_addr_real  = (restore_dmem_enable) ? cpu_write_addr : dmem_addr;
   assign restore_dmem_we = {restore_dmem_we_flag,restore_dmem_we_flag,restore_dmem_we_flag,restore_dmem_we_flag};
   assign dmem_we_real    = (restore_dmem_enable) ? restore_dmem_we : dmem_we;
   assign {dmem_data_real[3], dmem_data_real[2], dmem_data_real[1], dmem_data_real[0]} 
     = (restore_dmem_enable) ? cpu_write_data_in_reg : {dmem_wr_data[3], dmem_wr_data[2], dmem_wr_data[1],dmem_wr_data[0]};

    dmem #(.byte_num(2'b00)) dmem_0 (
        .clk(clk),
        .we(dmem_we_real[0]),
        .addr(dmem_addr_real),
        .wr_data(dmem_data_real[0]),
        .rd_data(dmem_rd_data[0])
    );
    
    dmem #(.byte_num(2'b01)) dmem_1 (
        .clk(clk),
        .we(dmem_we_real[1]),
        .addr(dmem_addr_real),
        .wr_data(dmem_data_real[1]),
        .rd_data(dmem_rd_data[1])
    );
    
    dmem #(.byte_num(2'b10)) dmem_2 (
        .clk(clk),
        .we(dmem_we_real[2]),
        .addr(dmem_addr_real),
        .wr_data(dmem_data_real[2]),
        .rd_data(dmem_rd_data[2])
    );
    
    dmem #(.byte_num(2'b11)) dmem_3 (
        .clk(clk),
        .we(dmem_we_real[3]),
        .addr(dmem_addr_real),
        .wr_data(dmem_data_real[3]),
        .rd_data(dmem_rd_data[3])
    );
    

    // UART
    assign uart_data_in = ex_store_value[7:0];
    assign uart_we = ((ex_alu_result == `UART_TX_ADDR) && ex_is_store) ? `ENABLE : `DISABLE;
    assign uart_tx = uart_data_out;

    uart uart_0 (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data(uart_data_in),
        .wr_en(uart_we),
        .uart_tx(uart_data_out),
        .uart_status(uart_tx_status)
    );

    uart_rx uart_rx_0 (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(uart_rx),
        .rd_data(uart_rd_data),
        .rd_en(uart_rd_en)
    );


    // GPIO
    assign gpi_data_in = gpi_in_reg;  //
    assign gpo_data_in = ex_store_value;
    assign gpo_we = ((ex_alu_result == `GPO_ADDR) && ex_is_store) ? `ENABLE : `DISABLE;
   always @(posedge clk ) begin
      gpo_out_reg = gpo_data_out;  //
   end
  
    gpi gpi_0 (
		.clk(clk),
		.rst_n(rst_n),
		.wr_data(gpi_data_in),
		.gpi_out(gpi_data_out)
    );

    gpo gpo_0 (
		.clk(clk),
		.rst_n(rst_n),
		.we(gpo_we),
		.wr_data(gpo_data_in),
		.gpo_out(gpo_data_out)
    );

    assign gpi1_data_in = gpi1_in_reg;  //
    assign gpo1_data_in = ex_store_value;
    assign gpo1_we = ((ex_alu_result == `GPO1_ADDR) && ex_is_store) ? `ENABLE : `DISABLE;
   always @(posedge clk ) begin
      gpo1_out_reg = gpo1_data_out;  //
   end

    gpi gpi_1 (
		.clk(clk),
		.rst_n(rst_n),
		.wr_data(gpi1_data_in),
		.gpi_out(gpi1_data_out)
    );
 
    gpo gpo_1 (
		.clk(clk),
		.rst_n(rst_n),
		.we(gpo1_we),
		.wr_data(gpo1_data_in),
		.gpo_out(gpo1_data_out)
    );



    // hardware counter
    hardware_counter hardware_counter_0 (
        .clk(clk),
        .rst_n(rst_n),
        .hc_out(hc_value)
    );

    
    //
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_reg_we <= `DISABLE;
            wb_dstreg_num <= 5'd0;
            wb_is_load <= `DISABLE;
            wb_alucode <= 6'd0;
            wb_alu_result <= 32'd0;
        end else begin
            wb_reg_we <= ex_reg_we;
            wb_dstreg_num <= ex_dstreg_num;
            wb_is_load <= ex_is_load;
            wb_alucode <= ex_alucode;
            wb_alu_result <= ex_alu_result;
        end
    end

    //====================================================================
    // write-back stage
    //====================================================================

    //
    assign gpi_value = gpi_data_out;
    assign gpo_value = gpo_data_out;
    assign gpi1_value = gpi1_data_out;
    assign gpo1_value = gpo1_data_out;
    assign uart_tx_value = {uart_tx_status, 31'd0};
    assign uart_value = {23'd0, uart_rd_en, uart_rd_data};
    
    function [31:0] load_value_sel(
        input 	     is_load,
        input [5:0]  alucode,
        input [31:0] alu_result,
        input [7:0]  dmem_rd_data_0, dmem_rd_data_1, dmem_rd_data_2, dmem_rd_data_3,
        input [31:0] uart_tx_value,
	input [31:0] uart_value,
        input [31:0] hc_value,
        input [31:0] gpi_value,
        input [31:0] gpo_value,
        input [31:0] gpi1_value,
        input [31:0] gpo1_value
    );

        begin
            if (is_load) begin
                case (alucode)
                    `ALU_LW: begin
                        if (alu_result == `HARDWARE_COUNTER_ADDR) begin
                            load_value_sel = hc_value;
                        end else if (alu_result == `UART_TX_ADDR) begin
                            load_value_sel = uart_tx_value;
                        end else if (alu_result == `UART_RX_ADDR) begin
                            load_value_sel = uart_value;
                        end else if (alu_result == `GPI_ADDR) begin
                            load_value_sel = gpi_value;
                        end else if (alu_result == `GPO_ADDR) begin
                            load_value_sel = gpo_value;
                       end else if (alu_result == `GPI1_ADDR) begin
                            load_value_sel = gpi1_value;
                        end else if (alu_result == `GPO1_ADDR) begin
                            load_value_sel = gpo1_value;
                        end else begin
                            load_value_sel = {dmem_rd_data_3, dmem_rd_data_2, dmem_rd_data_1, dmem_rd_data_0};
                        end
                    end
                    `ALU_LH: begin
                          case (alu_result[1:0])
                            2'b00: load_value_sel = {{16{dmem_rd_data_1[7]}}, dmem_rd_data_1, dmem_rd_data_0};
                            2'b01: load_value_sel = {{16{dmem_rd_data_2[7]}}, dmem_rd_data_2, dmem_rd_data_1};
                            2'b10: load_value_sel = {{16{dmem_rd_data_3[7]}}, dmem_rd_data_3, dmem_rd_data_2};
                            default: load_value_sel = {{16{dmem_rd_data_1[7]}}, dmem_rd_data_1, dmem_rd_data_0};
                          endcase // case (alu_result[1:0])
		    end
                    `ALU_LB: begin
                          case (alu_result[1:0])
                            2'b00: load_value_sel = {{24{dmem_rd_data_0[7]}}, dmem_rd_data_0};
                            2'b01: load_value_sel = {{24{dmem_rd_data_1[7]}}, dmem_rd_data_1};
                            2'b10: load_value_sel = {{24{dmem_rd_data_2[7]}}, dmem_rd_data_2};
                            2'b11: load_value_sel = {{24{dmem_rd_data_3[7]}}, dmem_rd_data_3};
                          endcase // case (alu_result[1:0])
                    end
                    `ALU_LHU: begin
                          case (alu_result[1:0])
                            2'b00: load_value_sel = {16'd0, dmem_rd_data_1, dmem_rd_data_0};
                            2'b01: load_value_sel = {16'd0, dmem_rd_data_2, dmem_rd_data_1};
                            2'b10: load_value_sel = {16'd0, dmem_rd_data_3, dmem_rd_data_2};
                            default: load_value_sel = {16'd0, dmem_rd_data_1, dmem_rd_data_0};
                          endcase // case (alu_result[1:0])
                    end
                    `ALU_LBU: begin
                          case (alu_result[1:0])
                            2'b00: load_value_sel = {24'd0, dmem_rd_data_0};
                            2'b01: load_value_sel = {24'd0, dmem_rd_data_1};
                            2'b10: load_value_sel = {24'd0, dmem_rd_data_2};
                            2'b11: load_value_sel = {24'd0, dmem_rd_data_3};
                          endcase // case (alu_result[1:0])
                    end 
                    default: load_value_sel = {dmem_rd_data_3, dmem_rd_data_2, dmem_rd_data_1, dmem_rd_data_0};
                endcase
            end else begin
                load_value_sel = 32'd0;
            end
        end
        
    endfunction

    assign wb_load_value = load_value_sel(wb_is_load, wb_alucode, wb_alu_result, dmem_rd_data[0],
                                          dmem_rd_data[1], dmem_rd_data[2], dmem_rd_data[3], uart_tx_value, uart_value, hc_value, gpi_value, gpo_value, gpi1_value, gpo1_value);
   
    
    assign wb_dstreg_value = wb_is_load ? wb_load_value : wb_alu_result;

   
    // wb stage
    assign regfile_we = wb_reg_we;
    assign regfile_dstreg_num = wb_dstreg_num;
    assign regfile_dstreg_value = wb_dstreg_value;

    // load命令の場合，メモリからロードされた値をtargetとする．
    //  src2にはaluで計算されたメモリアドレスにする．
    always @(posedge clk) begin
       iana_3_attr <= iana_2_attr;
       if (wb_is_load) begin
	  iana_3_src2 <= iana_2_dest;
	  iana_3_dest <= wb_load_value;
       end
       else begin
	  iana_3_src2 <= iana_2_src2;
	  iana_3_dest <= iana_2_dest;
       end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
	   iana_counter <= 32'd0;
        end 
	else if(!stall_flag) begin
           iana_counter <= iana_counter+1;
	end
    end

   //assign iana_out  = {iana_3_inst, iana_3_src2, iana_3_dest, iana_3_attr};
   assign iana_out  = {iana_3_pc, iana_3_src2, iana_3_dest, iana_3_attr};

   always @(posedge clk) begin
      if(restore_state_flag == 1) begin
	 restore_state <= 1;
      end
      else begin
	 restore_state <= 0;
      end
   end
   
   always @(posedge clk) begin
      if(register_write_flag  == 1) begin
	 restore_mem[cpu_write_addr] <= cpu_write_data_in_reg;
      end
   end

   always @(posedge clk) begin
      if(pc_write_flag == 1) begin
	 restore_pc <= cpu_write_data_in_reg;
      end
   end

endmodule
