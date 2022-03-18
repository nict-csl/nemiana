extern "C" {
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
};

#include "iana_cpu.h"

const char* p_state  = "GET /state";
const char* p_trace  = "GET /trace";
const char* p_write  = "POST /writ";
const char* p_resume = "GET /resum";
const char* p_reset  = "GET /reset";
const char* p_init   = "GET /init";
const char* p_data   = "GET /data";
const char* p_exit   = "GET /exit";
const char* p_run    = "GET /run";
const char* p_step   = "GET /step";
const char* p_stall  = "GET /stall";
const char* p_clear  = "GET /clear";

int step_mode = 0;
IanaCPU *iana_cpu;
const char * tail_msg =""
  "<a href='/step'>step</a></br>\n"
  "<a href='/data/reg/all'>reg all</a></br>\n"
  "<a href='/trace'>trace</a></br>\n"
  "<a href='/run'>run</a></br>\n"
  "<a href='/resume'>resume</a></br>\n"
  "\n";

void handle_ok(int client_sock,const char *msg){
  char response_message[2048];
  memset(response_message, 0, sizeof(response_message));
  sprintf(response_message,
	  "HTTP/1.0 200 OK\r\n"
	  "Content-Type: text/html\r\n"
	  "\r\n"
	  "%s\r\n", msg);

  send(client_sock, response_message, (int)strlen(response_message), 0);
  printf("%s", response_message);
}

static const char * header =   "HTTP/1.0 200 OK\r\n"
  "Content-Type: text/html\r\n"
  "\r\n";

void get_trace(int client_sock){

  send(client_sock, header, (int)strlen(header), 0);

  std::vector<TraceInfo>* trace_info = iana_cpu->get_trace();
  int num  = trace_info->size();
  char buf[num * 80];
  int pos =0;
  // The first and second attr is invalid(pipe line).
  for(int i=2;i<num;i++){
    pos +=sprintf(buf+pos, "attr2:%08X,%08X,%08X,%08X\r\n",
		  trace_info->at(i).val[3],
		  trace_info->at(i).val[2],
		  trace_info->at(i).val[1],
		  trace_info->at(i).val[0]);
  }
  trace_info->clear();

  printf("trace_info='%s'\n",buf);
  
  send(client_sock, buf, (int)strlen(buf), 0);
}

void get_state(int client_sock){
  send(client_sock, header, (int)strlen(header), 0);

  char buf[128];
  int len = sprintf(buf, "GPIO: %08X\r\n", iana_cpu->get_state());
  send(client_sock, buf, len, 0);
}

void cpu_reset(int client_sock){
  send(client_sock, header, (int)strlen(header), 0);

  iana_cpu->reset();
  //  iana_cpu->run();
  const char *buf = "cpu reset\r\n";
  send(client_sock, buf, (int)strlen(buf), 0);
}

void cpu_run(int client_sock){
  send(client_sock, header, (int)strlen(header), 0);

  int state = iana_cpu->get_state();
  printf("run state:%08X\n", state);

  if((state & 4) == 1){
    iana_cpu->resume();
  }

  iana_cpu->run();
  const char *buf = "cpu run\r\n";
  send(client_sock, buf, (int)strlen(buf), 0);
}

void cpu_step(int client_sock){
  send(client_sock, header, (int)strlen(header), 0);

  iana_cpu->exec_one_step();

  char buf[128];
  int val = iana_cpu->ReadPC();
  sprintf(buf, "execute 1 step(pc:%08X)\n", val);
  send(client_sock, buf, (int)strlen(buf), 0);
  send(client_sock, tail_msg, strlen(tail_msg), 0);
}

void cpu_clear(int client_sock){
  send(client_sock, header, (int)strlen(header), 0);

  iana_cpu->clear_trace();
  const char *buf = "trace queue cleared\r\n";
  send(client_sock, buf, (int)strlen(buf), 0);
  send(client_sock, tail_msg, strlen(tail_msg), 0);
}

void cpu_stall(int client_sock){
  send(client_sock, header, (int)strlen(header), 0);

  iana_cpu->stall();
  const char *buf = "trace queue cleared\r\n";
  send(client_sock, buf, (int)strlen(buf), 0);
  send(client_sock, tail_msg, strlen(tail_msg), 0);
}

void cpu_resume(int client_sock){
  send(client_sock, header, (int)strlen(header), 0);

  iana_cpu->resume();
  const char *buf = "cpu resumed\r\n";
  send(client_sock, buf, (int)strlen(buf), 0);
  send(client_sock, tail_msg, strlen(tail_msg), 0);
}

void cpu_init(int client_sock){
  send(client_sock, header, (int)strlen(header), 0);

  iana_cpu->init();
  const char *buf = "cpu initialized\r\n";
  send(client_sock, buf, (int)strlen(buf), 0);
  send(client_sock, tail_msg, strlen(tail_msg), 0);
}

void cpu_write(int client_sock, char *input_buf, int size){
  send(client_sock, header, (int)strlen(header), 0);

  char *p = input_buf;
  int state = iana_cpu->get_state();
  printf("state:%08X\n", state);

  if((state & 4) == 0){
    iana_cpu->stall();
  }
  
  while(!((*p !='\0')&&(p[3] !='\0')&&
	  (*p == '\r')&&(p[1] == '\n')&&
	  (p[2] == '\r')&&(p[3] == '\n'))){
    p++;
  }

  if((*p != '\0') && (p[3] != '\0')){
    char buf[128];
    p +=4;
    while(*p != '\0'){
      memcpy(buf, p, 18);
      buf[18] = '\0';
      p += 18;

      int addr, data;
      int num = sscanf(buf, "%08X %08X", &addr, &data);
      if(num==2){
	int type;

	if(addr >= 0x80000000){
	  iana_cpu->WriteRegister(addr & 0x0FFFFFFF, data);
	  type=1;
	}
	else if(addr >= 0x40000000){
	  iana_cpu->WritePC(data);
	  type=2;
	}
	else if(addr >= 0x20000000){
	  iana_cpu->WriteData(addr & 0x0FFFFFFF, data);
	  type=3;
	}
	else if(addr >= 0x10000000){
	  iana_cpu->WriteCode(addr & 0x0FFFFFFF, data);
	  type=4;
	}
	printf("write %d:%08X %08X\n", type, addr, data);
      }
      else{
	printf("unknown:%s\n", buf);
      }
    }
  }
  const char *buf = "write data to cpu\r\n";
  send(client_sock, buf, (int)strlen(buf), 0);
}

void cpu_data(int client_sock, char *input_buf, int size){
  send(client_sock, header, (int)strlen(header), 0);

  char *p = input_buf+strlen(p_data)+1;

  char buf[1024];
  strcpy(buf, "not found\n");
  int num;
  int val;

  if(strncmp(p, "reg/all", 7) == 0){
    char *b = buf;
    for(int i;i<32;i++){
      int val = iana_cpu->ReadRegister(i);
      b = b + sprintf(b, "%02d %08X\n", i, val);
    }
    b = b + sprintf(b, "%02d %08X\n", 32, iana_cpu->ReadPC());
  }
  else if(strncmp(p, "reg/", 4) == 0){
    sscanf(p+4, "%d", &num);
    val = iana_cpu->ReadRegister(num);
    sprintf(buf, "reg:%d %08X\n", num, val);
  }
  else if(strncmp(p, "data/", 5) == 0){
    sscanf(p+5, "%d", &num);
    val = iana_cpu->ReadData(num);
    sprintf(buf, "data:%d %08X\n", num, val);
  }
  else if(strncmp(p, "pc", 2) == 0){
    val = iana_cpu->ReadPC();
    sprintf(buf, "pc:%08X\n", val);
  }
  else if(strncmp(p, "code/", 5) == 0){
    sscanf(p+5, "%d", &num);
    val = iana_cpu->ReadCode(num);
    sprintf(buf, "code:%d %08X\n", num, val);
  }
  
  send(client_sock, buf, (int)strlen(buf), 0);
  send(client_sock, tail_msg, strlen(tail_msg), 0);
}

void handle_client(int client_sock){

  char input_buf[1024*1024];

  memset(input_buf, 0, sizeof(input_buf));
  int size = recv(client_sock, input_buf, sizeof(input_buf)-10, 0);
  printf("%s", input_buf);

  if(strncmp(input_buf, p_init, strlen(p_init))==0){
    printf("init\n");
    cpu_init(client_sock);
  }
  else if(strncmp(input_buf, p_state, strlen(p_state))==0){
    printf("state\n");
    get_state(client_sock);
  }
  else if(strncmp(input_buf, p_trace, strlen(p_trace))==0){
    printf("trace\n");
    get_trace(client_sock);
  }
  else if(strncmp(input_buf, p_resume, strlen(p_resume))==0){
    printf("resume\n");
    cpu_resume(client_sock);
  }
  else if(strncmp(input_buf, p_clear, strlen(p_clear))==0){
    printf("clear\n");
    cpu_clear(client_sock);
  }
  else if(strncmp(input_buf, p_stall, strlen(p_stall))==0){
    printf("stall\n");
    cpu_stall(client_sock);
  }
  else if(strncmp(input_buf, p_reset, strlen(p_reset))==0){
    printf("reset\n");
    cpu_reset(client_sock);
  }
  else if(strncmp(input_buf, p_run, strlen(p_run))==0){
    printf("run\n");
    cpu_run(client_sock);
  }
  else if(strncmp(input_buf, p_step, strlen(p_step))==0){
    printf("step\n");
    cpu_step(client_sock);
  }
  else if(strncmp(input_buf, p_write, strlen(p_write))==0){
    printf("write\n");
    cpu_write(client_sock, input_buf, size);
  }
  else if(strncmp(input_buf, p_data, strlen(p_data))==0){
    printf("data\n");
    cpu_data(client_sock, input_buf, size);
  }
  else if(strncmp(input_buf, p_exit, strlen(p_exit))==0){
    printf("exit\n");
    exit(0);
  }
  else{
    printf("hello\n");
    handle_ok(client_sock, "Hello");
  }
  fflush(stdout);
  close(client_sock);
}
		   
void main_loop(int port_num){
  iana_cpu  = new IanaCPU();
  iana_cpu->set_trace_on();
  //iana_cpu->run();
  
  int server_sock;
  struct sockaddr_in addr;
  struct sockaddr_in client_addr;
  int yes = 1;
  server_sock = socket(AF_INET, SOCK_STREAM, 0);
  if (server_sock < 0) {
    perror("socket");
    return;
  }
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port_num);
  addr.sin_addr.s_addr = INADDR_ANY;
  setsockopt(server_sock,
	     SOL_SOCKET, SO_REUSEADDR, (const char *)&yes, sizeof(yes));
  fprintf(stderr, "bind\n");
  if (bind(server_sock, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
    perror("bind");
    return;
  }
  fprintf (stderr, "listed\n");
  if (listen(server_sock, 5) != 0) {
    perror("listen");
    return;
  }

  fprintf (stderr, "enter main loop\n");

  while (1) {
    socklen_t len = sizeof(client_addr);
    int client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &len);
    fprintf (stderr, "accept\n");
    fflush(stdout);
    if (client_sock < 0) {
      perror("accept");
      break;
    }
    handle_client(client_sock);
    fflush(stdout);
  }

  close(server_sock);
}


int main(int argc, char** argv){
  int port_num = 8008;
  if(argc>1){
    port_num = atoi(argv[1]);
  }
  
  main_loop(port_num);
  
  return 0;
}
