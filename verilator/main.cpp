#include <iostream>
#include <verilated.h>
#include "Vcpu.h"

int timer = 0;

int main(int argc, char **argv){

  Verilated::commandArgs(argc, argv);
  Vcpu* dut=new Vcpu();

  dut->clock=0;
  dut->reset=1;
  dut->cpu_write_addr_in = 0;
  dut->cpu_write_data_in = 0;
  dut->cpu_write_enable_in = 0;
  dut->cpu_ctrl_in = 1;

  while(timer<100){
    dut->eval();
    timer++;
  }

  int i;
  for(i=0;i<100;i++){
    dut->clock = !dut->clock;
    dut->eval();
    timer++;
    dut->clock = !dut->clock;
    dut->eval();
    timer++;
  }
  dut->cpu_ctrl_in = 0;

  unsigned char *a  = (dut->cpu__DOT__cpu_top__DOT__dmem_3__DOT__mem);
  
  for(i=0;i<3000;i++){
    dut->clock = !dut->clock;
    dut->eval();
    timer++;

    printf("attr2:%08X,%08X,%08X,%08X, %d\n",
	   dut->iana_out[3],
	   dut->iana_out[2],
	   dut->iana_out[1],
	   dut->iana_out[0],
	   dut->is_stall_enabled_out
	   );

    dut->clock = !dut->clock;
    dut->eval();
    timer++;
  }
}
