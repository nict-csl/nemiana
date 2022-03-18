struct in_addr {
  unsigned long s_addr;
};

struct sockaddr_in {
  short sin_family;
  unsigned short sin_port;
  struct in_addr sin_addr;
  char sin_zero[8];
};
#define	PF_INET		2	/* IP protocol family.  */
enum __socket_type
{
  SOCK_STREAM = 1,		/* Sequenced, reliable, connection-based
				   byte streams.  */
#define SOCK_STREAM SOCK_STREAM
  SOCK_DGRAM = 2,		/* Connectionless, unreliable datagrams
				   of fixed maximum length.  */
#define SOCK_DGRAM SOCK_DGRAM
  SOCK_RAW = 3,			/* Raw protocol interface.  */
#define SOCK_RAW SOCK_RAW
  SOCK_RDM = 4,			/* Reliably-delivered messages.  */
#define SOCK_RDM SOCK_RDM
  SOCK_SEQPACKET = 5,		/* Sequenced, reliable, connection-based,
				   datagrams of fixed maximum length.  */
#define SOCK_SEQPACKET SOCK_SEQPACKET

#define SOCK_MAX (SOCK_SEQPACKET + 1)
  /* Mask which covers at least up to SOCK_MASK-1.
     The remaining bits are used as flags. */
#define SOCK_TYPE_MASK 0xf

  /* Flags to be ORed into the type parameter of socket and socketpair and
     used for the flags parameter of accept4.  */

  SOCK_CLOEXEC = 0x10000000,	/* Atomically set close-on-exec flag for the
				   new descriptor(s).  */
#define SOCK_CLOEXEC SOCK_CLOEXEC

  SOCK_NONBLOCK = 0x20000000	/* Atomically mark descriptor(s) as
				   non-blocking.  */
#define SOCK_NONBLOCK SOCK_NONBLOCK
};


int socket(int domain, int type, int protocol);
int connect(int sockfd, const struct sockaddr_in *addr,
	    int addrlen);
