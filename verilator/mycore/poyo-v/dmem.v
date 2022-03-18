//
// dmem
//


`include "define.vh"

module dmem #(parameter byte_num = 2'b00) (
    input wire clk,
    input wire we,
    input wire [31:0] addr,
    input wire [7:0] wr_data,
    output wire [7:0] rd_data
);

    reg [7:0] mem [0:16383]; 
//   reg [7:0]  mem [0:8191];  // 64KiB(16bitアドレス空�?)
//   reg [7:0]  mem [0:4095];  // 64KiB(16bitアドレス空�?)
    reg [13:0] addr_sync;  // 64KiBを表現するための14bitアドレス(下�?2bitはここでは�?慮しな�?)
    
    initial begin
        case (byte_num)
            2'b00: $readmemh({`MEM_DATA_PATH, "data0.hex"}, mem);
            2'b01: $readmemh({`MEM_DATA_PATH, "data1.hex"}, mem);
            2'b10: $readmemh({`MEM_DATA_PATH, "data2.hex"}, mem);
            2'b11: $readmemh({`MEM_DATA_PATH, "data3.hex"}, mem);
        endcase
    end      
   
    always @(posedge clk) begin
        if (we) mem[addr[15:2]] <= wr_data;
        addr_sync <= addr[15:2];
    end

    assign rd_data = mem[addr_sync];

endmodule
