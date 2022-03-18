`define MEM_DATA_PATH "../target/hex/"
`define SYSCLK_FREQ      10000000
`define SYSCLK_FREQ_HALF  5000000
`define BAUD_RATE 115200
`define DMEM_START_ADDR      32'h80000000
`define DMEM_START_ADDR_MASK 32'h0FFFFFFF
`define DMEM_SIZE            32'h8000
`define SMEM_START_ADDR      32'h40000000
`define SMEM_START_ADDR_MASK 32'h3FFFFFFF
`define SMEM_SIZE            32'h100000
`define BMEM_START_ADDR      32'h80000000
`define BMEM_START_ADDR_MASK 32'h7FFFFFFF
`define BMEM_SIZE            32'h2000

// address for hardware counter
`define HARDWARE_COUNTER_ADDR 32'h20010

// address for UART
//`define UART_TX_ADDR 32'h20020
//`define UART_RX_ADDR 32'h20030
`define RESET_ADDR 32'h20010000
`define UART_TX_ADDR 32'h10013000
`define UART_RX_ADDR 32'h10013004
// address for GPIO
`define GPI_ADDR 32'h20040
`define GPO_ADDR 32'h20050
`define GPI1_ADDR 32'h20060
`define GPO1_ADDR 32'h20070
`define SMEM_MODE_ADDR 32'h20080

`define ENABLE  1'b1
`define DISABLE 1'b0

`define TYPE_NONE 3'd0
`define TYPE_U    3'd1
`define TYPE_J    3'd2
`define TYPE_I    3'd3
`define TYPE_B    3'd4
`define TYPE_S    3'd5
`define TYPE_R    3'd6

`define LUI    7'b0110111
`define AUIPC  7'b0010111
`define JAL    7'b1101111
`define JALR   7'b1100111
`define BRANCH 7'b1100011
`define LOAD   7'b0000011
`define STORE  7'b0100011
`define OPIMM  7'b0010011
`define OP     7'b0110011
`define SYSTEM 7'b1110011

`define REG_NONE 1'd0
`define REG_RD   1'd1

`define ALU_LUI   6'd0
`define ALU_JAL   6'd1
`define ALU_JALR  6'd2
`define ALU_BEQ   6'd3
`define ALU_BNE   6'd4
`define ALU_BLT   6'd5
`define ALU_BGE   6'd6
`define ALU_BLTU  6'd7
`define ALU_BGEU  6'd8
`define ALU_LB    6'd9
`define ALU_LH    6'd10
`define ALU_LW    6'd11
`define ALU_LBU   6'd12
`define ALU_LHU   6'd13
`define ALU_SB    6'd14
`define ALU_SH    6'd15
`define ALU_SW    6'd16
`define ALU_ADD   6'd17
`define ALU_SUB   6'd18
`define ALU_SLT   6'd19
`define ALU_SLTU  6'd20
`define ALU_XOR   6'd21
`define ALU_OR    6'd22
`define ALU_AND   6'd23
`define ALU_SLL   6'd24
`define ALU_SRL   6'd25
`define ALU_SRA   6'd26
`define ALU_NOP   6'd63

`define OP_TYPE_NONE 2'd0
`define OP_TYPE_REG  2'd1
`define OP_TYPE_IMM  2'd2
`define OP_TYPE_PC   2'd3
`define NOP_INST     32'H00000013

`define STALL_TRUE 1'd1
`define STALL_FALSE 1'd0
