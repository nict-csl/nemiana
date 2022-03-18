//-------------------------------------------------------------------
//-------------------------------------------------------------------
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

void set_csr(void*);
void machine_mode(void);
void socket_test();

int ccc(){
  char buf[128];
  int fd2 = open("test2.txt", O_RDONLY);
  int num = read(fd2, buf, 20);
  int fd = open("test3.txt", O_WRONLY);
  char * s = "This is string from IANA CPU";
  write(fd, s, 28);
  write(fd, buf, 20);

  socket_test(fd);
}


void notmain() {
  int *xxx = (int*)machine_mode;
  set_csr(xxx);
  ccc(123, 345, 567);
}
