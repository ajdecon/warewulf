//
// Warewulf Monitor Aggregator (wwmon_aggregator.c)
//
// Copyright(c) 2011 Anthony Salgado & Krishna Muriki
//

#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <arpa/inet.h>
#include <fcntl.h>

#include "globals.h"
#include "util.c"

char local_sysname[MAX_SYSNAME_LEN];
fd_set rfds, wfds;

//Global structure array with values of each socket
sockdata sock_data[FD_SETSIZE];
//Global Database to hold data of each socket
sqlite3 *db; // database pointer

int
writeHandler(int fd) 
{

  char sbuf[MAXPKTSIZE];
  sbuf[0] = '\0';
 
  apphdr *app_h = (apphdr *) sbuf;
  appdata *app_d = (appdata *) (sbuf + sizeof(apphdr));

  // TODO : Add writeHandler logic here
  strcpy(app_d->payload,"Send Data");
  app_h->len = strlen(app_d->payload);

  fprintf(stderr,"About to write on FD - %d\n",fd);
  if (sendall(fd, sbuf, sizeof(apphdr) + strlen(app_d->payload)) == -1) {
      FD_CLR(fd, &wfds);
      close(fd);
  }

  FD_CLR(fd, &wfds);
  FD_SET(fd, &rfds);

  return(0);
}

int
readHandler(int fd)
{
  fprintf(stderr,"About to read on FD - %d\n",fd);

  char rbuf[MAXPKTSIZE];
  rbuf[0] = '\0';
  int readbytes;
  json_object *jobj;

  // First check if there is any remaining payload from previous
  // transmission for this socket and decide the # of bytes to read.
  int numtoread;
  if( sock_data[fd].r_payloadlen > 0 && sock_data[fd].r_payloadlen < MAXPKTSIZE-1 ) {
      numtoread = sock_data[fd].r_payloadlen;
  } else {
      numtoread = MAXPKTSIZE-1;
  }

  if ((readbytes=recv(fd, rbuf, numtoread, 0)) == -1) {
      perror("recv");
      FD_CLR(fd, &rfds);
      sock_data[fd].validinfo = 0;
      close(fd);
      return(0);
  }
  rbuf[readbytes]='\0';
  fprintf(stderr, "Rx a string of size %d - %s\n",readbytes,rbuf);

  // Is this required ?
  if (strlen(rbuf) == 0)
  {
      fprintf(stderr,"\nSeams like the remote client connected\n");
      fprintf(stderr,"to this socket has closed its connection\n");
      fprintf(stderr,"So I'm closing the socket\n");
      FD_CLR(fd, &rfds);
      sock_data[fd].validinfo = 0;
      close(fd);
      return(0);
  }
 
  // If the read buffer is from pending transmission append to accuralbuf
  // Or else treat it as a new packet. 
  if (sock_data[fd].r_payloadlen > 0) {
     strcat(sock_data[fd].accural_buf,rbuf);
     sock_data[fd].r_payloadlen = sock_data[fd].r_payloadlen - readbytes;
  } else {
     apphdr *app_h = (apphdr *) rbuf;
     appdata *app_d = (appdata *) (rbuf + sizeof(apphdr));

     printf("Len of the payload - %d, %s\n", app_h->len,app_d->payload);
 
     sock_data[fd].accural_buf = (char *) malloc(app_h->len);
     strcpy(sock_data[fd].accural_buf,app_d->payload);
     sock_data[fd].r_payloadlen = app_h->len - strlen(sock_data[fd].accural_buf);
  }

  if (sock_data[fd].r_payloadlen > 0) {
     //Still has more reading to do
     return(0);
  }

  printf("Done reading totally\n");

  jobj = json_tokener_parse(sock_data[fd].accural_buf); // get json from string
  sock_data[fd].validinfo = 1;
  
  // update database call
  update_db(jobj, db);

  free(sock_data[fd].accural_buf);

  FD_CLR(fd, &rfds);
  FD_SET(fd, &wfds);
  return(0);
}

void
readndumpData(int fd)
{

  struct sockaddr_in their_addr;
  int addr_len, numbytes;
  char buf[MAXPKTSIZE];
  json_object *json_db = json_object_new_object();

  addr_len = sizeof(struct sockaddr);
  if ((numbytes=recvfrom(fd, buf, MAXPKTSIZE-1 , 0,
              (struct sockaddr *)&their_addr, &addr_len)) == -1) {
      perror("recvfrom");
  }
  printf("got packet from %s\n",inet_ntoa(their_addr.sin_addr));
  printf("packet is %d bytes long\n",numbytes);
  buf[numbytes] = '\0';
  printf("packet contains \"%s\"\n",buf);

  sqlite3_exec(db, "select * from wwstats", json_from_db, json_db, NULL);

  // send json_object over socket to wwstats
  if ((numbytes=sendto(fd, json_object_to_json_string(json_db), strlen(json_object_to_json_string(json_db)), 0,
		       (struct sockaddr *)&their_addr, sizeof(struct sockaddr))) == -1) {
    perror("sendto");
  }  
  printf("sent %d bytes to %s\n", numbytes, inet_ntoa(their_addr.sin_addr));

  return;
}

int
setupSockets(int port,int *stcp,int *sudp)
{

  // new TCP socket
  if((*stcp = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
    perror("TCP socket");
    return -1;
  }

  // new UDP socket
  if((*sudp = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
    perror("UDP socket");
    return -1;
  }

  // don't whine about address already in use
  int n = 1;
  if(setsockopt(*stcp, SOL_SOCKET, SO_REUSEADDR, (char *)&n, sizeof(n)) < 0) {
    perror("TCP setsockopt");
    return -1;
  }
  if(setsockopt(*sudp, SOL_SOCKET, SO_REUSEADDR, (char *)&n, sizeof(n)) < 0) {
    perror("UDP setsockopt");
    return -1;
  }

  // bind socket to some port
  struct sockaddr_in sin;
  bzero(&sin, sizeof(sin));
  sin.sin_family = AF_INET;
  sin.sin_port = htons(port);
  sin.sin_addr.s_addr = INADDR_ANY;
  if(bind(*stcp, (struct sockaddr*) &sin, sizeof(sin)) < 0) {
    perror("TCP bind");
    return -1;
  }
  if(bind(*sudp, (struct sockaddr*) &sin, sizeof(sin)) < 0) {
    perror("UDP bind");
    return -1;
  }

  // listen for incoming connections
  if(listen(*stcp, 5) < 0) {
    perror("TCP listen");
    return -1;
  }

  gethostname(local_sysname,sizeof(local_sysname));
  return(0);
}

int
acceptConn(int fd)
{
  struct sockaddr_in sin;
  socklen_t sinlen = sizeof(sin);
  bzero(&sin, sinlen);

  int c;

  if((c = accept(fd, (struct sockaddr*) &sin, &sinlen)) < 0) {
    perror("accept");
    return -1;
  }
  strcpy(sock_data[c].remote_sock_ipaddr,inet_ntoa(sin.sin_addr));

  fprintf(stderr,"Accepted a new connection on fd - %d from %s\n",c,sock_data[c].remote_sock_ipaddr);
  // Register interest in a write on this socket
  FD_SET(c, &wfds);

  return(c);
}

int
main(int argc, char *argv[])
{
  int stcp = -1;
  int sudp = -1;
  int rc = -1;

  if(argc != 2) {
    fprintf(stderr, "Usage: %s [port]\n", argv[0]);
    exit(1);
  }

  bzero(sock_data,sizeof(sock_data));

  // Prepare to accept clients
  FD_ZERO(&rfds);
  FD_ZERO(&wfds);

  // Get the database ready
  // Attempt to open database & check for failure
  if( rc = sqlite3_open("wwmon.db", &db)  ){
    fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
    exit(1);
  }

  // Open TCP (SOCK_STREAM) Socket, bind to the port given and listen for connections
  //if((stcp = setupSockets(atoi(argv[1]))) < 0)
  if((setupSockets(atoi(argv[1]),&stcp,&sudp)) < 0)
    exit(1);

  printf("Our listen sock # is - %d & UDP sock # is - %d \n",stcp,sudp);
  //printf("FD_SETSIZE - %d\n",FD_SETSIZE);

  //Add the created TCP & UDP sockets to the read set of file descriptors
  FD_SET(stcp, &rfds);
  FD_SET(sudp, &rfds);

  // Event loop
  while(1) {

    int n = 0;
    fd_set _rfds, _wfds;

    memcpy(&_rfds, &rfds, sizeof(fd_set));
    memcpy(&_wfds, &wfds, sizeof(fd_set));

    // Block until there's an event to handle
    // Select function call is made; return value 'n' gives the number of FDs ready to be serviced
    if(((n = select(FD_SETSIZE, &_rfds, &_wfds, NULL, 0)) < 0) && 
       (errno != EINTR)) {
      perror("select");
      exit(1);
    }
 
    // Handle events
    for(int i = 0; (i < FD_SETSIZE) && n ; i++) {

      if(FD_ISSET(i, &_rfds)) {
	// Handle our main mother, TCP listening socket differently
	if(i == stcp) {
	  if(acceptConn(stcp) < 0)
	    exit(1);
        // Handle our UDP socket differently
        } else if(i == sudp) {
          readndumpData(sudp);
        } else {
	  fprintf(stderr,"File descriptor %d is ready for reading .. call'g readHLR\n",i);
          readHandler(i);
	}
	n--;
      }
      if(FD_ISSET(i, &_wfds)) {
	  fprintf(stderr,"File descriptor %d is ready for writing .. call'g writeHLR\n",i);
	  writeHandler(i);
	n--;
      } 
    }
  }
}
