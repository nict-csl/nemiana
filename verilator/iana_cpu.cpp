#include <iostream>
#include <verilated.h>
#include "Vcpu.h"
#include "iana_cpu.h"

static const unsigned int CPU_RESET         = (1<<0);
static const unsigned int RESTORE_MODE      = (1<<1);
static const unsigned int UPDATE_REGISTER   = (1<<6);
static const unsigned int UPDATE_PC         = (1<<7);
static const unsigned int TRACE_FAULT       = (1<<13);
static const unsigned int FIFO_START        = (1<<8);
static const unsigned int FIFO_RESET        = (1<<9);
static const unsigned int CPU_RESUME        = (1<<14);
static const unsigned int UPDATE_FROM_DMA   = ((1<<15)|(1<<16));

IanaCPU::IanaCPU(){
  cpu=NULL;
  init();
}

void IanaCPU::reset(){
  timer = 0;
  trace_flag = 0;
  cpu->cpu_ctrl_in = 1;

  while(timer<100){
    cpu->eval();
    timer++;
  }

  int i;
  for(i=0;i<100;i++){
    cpu->clock = !cpu->clock;
    cpu->eval();
    cpu->clock = !cpu->clock;
    cpu->eval();
  }
  cpu->cpu_ctrl_in = 0;
  trace_flag = 1;
  reset_trace_info();
  //  unsigned int *a = (cpu->cpu__DOT__cpu_top__DOT__imem__DOT__mem);
  //for(int i=0;i<100;i++){
  //    int addr = ( (0x20010000 +i) & 0x0fffffff) - 0x10000;
  //  fprintf(stderr,  "%08X=%08X\n", addr , a[addr/4]);
  //}
}

void IanaCPU::init(){
  if(cpu != NULL){
    delete cpu;
  }
  
  cpu=new Vcpu();
  timer = 0;
  trace_flag = 0;
  
  cpu->clock=0;
  cpu->reset=1;
  cpu->cpu_write_addr_in = 0;
  cpu->cpu_write_data_in = 0;
  cpu->cpu_write_enable_in = 0;
  cpu->stall_enable_in  = 0;
  cpu->cpu_resume = 0;

  reset();
  
}

void IanaCPU::clear_trace(){
  reset_trace_info();
}

void IanaCPU::stall(){
  printf("stall()::before state:%08X\n", get_state());
  cpu->stall_enable_in  = 1;
  for(int i=0;i<3;i++){
    cpu->clock = !cpu->clock;
    cpu->eval();
    cpu->clock = !cpu->clock;
    cpu->eval();
  }
  cpu->stall_enable_in  = 0;
  for(int i=0;i<3;i++){
    cpu->clock = !cpu->clock;
    cpu->eval();
    cpu->clock = !cpu->clock;
    cpu->eval();
  }
  printf("stall()::after state:%08X\n", get_state());
}

void IanaCPU::resume(){
  reset_trace_info();
  cpu->cpu_resume = 1;
  int i;
  for(i=0;i<10;i++){
    cpu->clock = !cpu->clock;
    cpu->eval();
    cpu->clock = !cpu->clock;
    cpu->eval();
  }
  cpu->clock = !cpu->clock;
  cpu->eval();
  // clock=1;

  cpu->cpu_resume = 1;
  for(i=0;i<10;i++){
    cpu->clock = !cpu->clock;
    cpu->eval();
    cpu->clock = !cpu->clock;
    cpu->eval();
  }
  // clock=1;
  cpu->cpu_resume = 0;
  cpu->clock = !cpu->clock;
  cpu->eval();
  // clock=0;
  i=0;
  while((i<100)&&((cpu->is_stall_enabled_out)==1)){
    cpu->clock = !cpu->clock;
    cpu->eval();
    printf("attr3:%08X,%08X,%08X,%08X, %d\n",
	   cpu->iana_out[3],
	   cpu->iana_out[2],
	   cpu->iana_out[1],
	   cpu->iana_out[0],
	   cpu->is_stall_enabled_out
	   );
    printf("data2:%08X %08X\n",
	   cpu->cpu__DOT__cpu_top__DOT__prev_resume_requested1,
	   cpu->cpu__DOT__cpu_top__DOT__prev_resume_requested2
	   );
    cpu->clock = !cpu->clock;
    cpu->eval();
    i++;
  }
  /// 2022/01/21
  //reset_trace_info();
}

void IanaCPU::run(){
  int i=0;
  while(((cpu->is_stall_enabled_out)==0)
	&&(i<3000)){
    exec_one_step();
    //    for(int j=0;j<31;j++){
    //      printf("reg %02d:%08X\n",j, ReadRegister(j));
    //    }

    i++;
  }
}

void IanaCPU::print_pc(int i){
  int pc1 = ReadPC();
  int pc2 = cpu->cpu__DOT__cpu_top__DOT__next_PC_prev;
  printf("PC%d:%08X %08X\n",i, pc1, pc2);
}

void IanaCPU::exec_one_step(){
  print_pc(1);
  cpu->eval();
  print_pc(2);
  cpu->clock = !cpu->clock;
  print_pc(3);
  cpu->eval();
  print_pc(4);
  if(trace_flag!=0){
    unsigned int *a = (cpu->cpu__DOT__cpu_top__DOT__imem__DOT__mem);
    int addr = ( 0x20010100 & 0x0fffffff) - 0x10000;
    //    fprintf(stderr,  "2010100=%08X\n", a[addr]);

    print_pc(5);
    printf("attr2:%08X,%08X,%08X,%08X, %d\n",
	   cpu->iana_out[3],
	   cpu->iana_out[2],
	   cpu->iana_out[1],
	   cpu->iana_out[0],
	   cpu->is_stall_enabled_out
	   //	   cpu->cpu__DOT__cpu_top__DOT__imem_rd_data,
	   //	   a[addr/4]
	   );
    fflush(stdout);
    trace_info_list.emplace_back(cpu->iana_out);
  }
  print_pc(6);
  cpu->eval();
  print_pc(7);
  cpu->clock = !cpu->clock;
  print_pc(8);
  cpu->eval();
  print_pc(9);
  cpu->eval();
  print_pc(10);
  timer++;
}

void IanaCPU::reset_trace_info(){
  trace_info_list.clear();
}

int IanaCPU::get_state(){
  return cpu->cpu_state;
}

int IanaCPU::ReadData(int addr){
  unsigned char* a[4]   = {
			     (cpu->cpu__DOT__cpu_top__DOT__dmem_0__DOT__mem),
			     (cpu->cpu__DOT__cpu_top__DOT__dmem_1__DOT__mem),
			     (cpu->cpu__DOT__cpu_top__DOT__dmem_2__DOT__mem),
			     (cpu->cpu__DOT__cpu_top__DOT__dmem_3__DOT__mem)};
  unsigned char d[4];
  int i;
  addr = (addr & 0x0fffffff);
  for(i=0;i<4;i++){
    d[3-i] = (a[i])[addr/4];
  }

  return *((int*)d);
}

void IanaCPU::WriteData(int addr, int data){
  unsigned char* a[4]   = {
			     (cpu->cpu__DOT__cpu_top__DOT__dmem_0__DOT__mem),
			     (cpu->cpu__DOT__cpu_top__DOT__dmem_1__DOT__mem),
			     (cpu->cpu__DOT__cpu_top__DOT__dmem_2__DOT__mem),
			     (cpu->cpu__DOT__cpu_top__DOT__dmem_3__DOT__mem)};
  unsigned char d[4];
  *((int *)d) = data;

  int i;
  addr = (addr & 0x0fffffff);
  for(i=0;i<4;i++){
    (a[i])[addr/4] = d[i];
  }
}

int IanaCPU::ReadCode(int addr){
  unsigned int *a = (cpu->cpu__DOT__cpu_top__DOT__imem__DOT__mem);
  addr = (addr & 0x0fffffff) - 0x10000;
  return a[addr/4];
}

void IanaCPU::WriteCode(int addr, int data){
  unsigned int *a = (cpu->cpu__DOT__cpu_top__DOT__imem__DOT__mem);
  addr = (addr & 0x0fffffff) - 0x10000;
  a[addr/4] = data;
}

int IanaCPU::ReadRegister(int addr){
  if(addr==0){
    return 0;
  }else{
    unsigned int *a = cpu->cpu__DOT__cpu_top__DOT__regfile_0__DOT__regfile;
    addr &= 31;
    return a[addr-1];
  }
}

void IanaCPU::WriteRegister(int addr, int data){
  if(addr>0){
    unsigned int *a = cpu->cpu__DOT__cpu_top__DOT__regfile_0__DOT__regfile;
    addr &= 31;
    a[addr-1] = data;
  }
}

int IanaCPU::ReadPC(void){
  return cpu->cpu__DOT__cpu_top__DOT__PC;
}

void IanaCPU::WritePC(int data){
  printf ("WritePC%08X\n",data);
  cpu->cpu__DOT__cpu_top__DOT__PC = data;
  cpu->cpu__DOT__cpu_top__DOT__next_PC_prev = data;
  int pc = ReadPC();
  printf("Write PC:%08X\n",pc);
}
