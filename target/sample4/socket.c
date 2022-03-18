#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "my_socket.h"

//char *target_addr="8.8.8.8";

#define INET_ADDR(a,b,c,d) (((((a)*256 + (b))*256 + (c))*256)+(d))
int target_addr=INET_ADDR(172,217,31,164);
void bzero(void *buf, int count){
  int i;

  for(i=0;i<count;i++){
    ((char*)buf)[i] =0;
  }
}

int htons(int d){
  int res;
  res  = (d & 0x000000FF)<< 8;
  res += (d & 0x0000FF00)>> 8;

  return res;
}

int strlen(char*c){
  int i=0;

  while(*c != '\0'){
    c++;
    i++;
  }
  
  return i;
}

char *send_data="GET /index.html HTTP/1.0\r\n\r\n";

void socket_test(int fd) {
  int sockfd;
  struct sockaddr_in client_addr;

  sockfd = socket(PF_INET, SOCK_STREAM, 0);
  bzero((char *)&client_addr, sizeof(struct sockaddr_in));
  client_addr.sin_family = PF_INET;
  client_addr.sin_addr.s_addr = target_addr;
  client_addr.sin_port = htons(80);
  connect(sockfd, (struct sockaddr *)&client_addr,sizeof(client_addr));
  int buf_len=28;
  write(sockfd, send_data, buf_len);
  char buf[100];
  buf_len = read(sockfd, buf, 100);
  write(fd, buf, 100);
}  
