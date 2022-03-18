#include <vector>

class Vcpu;

class TraceInfo{
 public:
  unsigned int val[4];

  TraceInfo(){
  }
  TraceInfo(const TraceInfo &org){
    for(int i=0;i<4;i++){
      val[i] = org.val[i];
    }
  }
  TraceInfo(const unsigned int * org){
    for(int i=0;i<4;i++){
      val[i] = org[i];
    }
  }
};

class IanaCPU {
 private:
  Vcpu * cpu;
  int timer;
  int trace_flag;
 public:
  IanaCPU(void);
  void init(void);
  void reset(void);
  void resume(void);
  void stall(void);
  void trace(void);
  void clear_trace(void);
  void write(void);
  void run(void);
  void exec_one_step(void);
  void reset_trace_info(void);
  void set_trace_on(){
    trace_flag=1;
  }
  void reset_trace_on(){
    trace_flag=0;
  }
  std::vector<TraceInfo> trace_info_list;

  std::vector<TraceInfo>* get_trace(){
    return &trace_info_list;
  }

  int get_state(void);

  int ReadData(int addr);
  void WriteData(int addr, int data);
  int ReadCode(int addr);
  void WriteCode(int addr, int data);
  int ReadRegister(int addr);
  void WriteRegister(int addr, int data);
  int ReadPC(void);
  void WritePC(int data);
  void print_pc(int i);
};
