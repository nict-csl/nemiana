#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stddef.h>
#include "my_socket.h"

#define OPEN_NUM  1
#define READ_NUM  2
#define WRITE_NUM 3
#define SOCKET_NUM 4
#define CONNECT_NUM 5
#define CLOSE_NUM 6
#define EXIT_NUM 7

int syscall(int arg1, int arg2, int arg3, int arg4);

int open(const char *pathname, int flags, ...){
  int res = syscall(OPEN_NUM, (int)pathname, (int)flags, 0);
  return res;
}

_READ_WRITE_RETURN_TYPE read (int fd, void *buf, size_t nbyte){
  int res = syscall(READ_NUM, (int)fd, (int)buf, (int)nbyte);
  return (_READ_WRITE_RETURN_TYPE )res;
}

ssize_t write(int fd, const void*buf, size_t count){
  int res = syscall(WRITE_NUM, (int)fd, (int)buf, (int)count);
  return (ssize_t)res;
}

int close(int fd){
  return 0;
}

int socket(int domain, int type, int protocol){

  int res = syscall(SOCKET_NUM, domain, type, protocol);
  return res;
}

int connect(int sockfd, const struct sockaddr_in *addr,
	    int addrlen){
  int res = syscall(CONNECT_NUM, sockfd, (int)addr, addrlen);
  return res;
}

void exit(int status){
  int res = syscall(EXIT_NUM, status, 0, 0);
}
