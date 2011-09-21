/*
 * Copyright (c) 2001-2003 Gregory M. Kurtzer
 * 
 * Copyright (c) 2003-2011, The Regents of the University of California,
 * through Lawrence Berkeley National Laboratory (subject to receipt of any
 * required approvals from the U.S. Dept. of Energy).  All rights reserved.
 *
 * Contributed by Anthony Salgado & Krishna Muriki
 * Warewulf Monitor (wwmon_aggregator.c)
 *
 */

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

#include "util.c"

char local_sysname[MAX_NODENAME_LEN];
fd_set rfds, wfds;

//Global structure array with values of each socket
sockdata sock_data[FD_SETSIZE];
//Global Database to hold data of each socket
static sqlite3 *db; // database pointer

int
writeHandler(int fd) 
{
  // Should we assume that even the TCP send's cannot be made when we want ?
  // In other words is it possible that TCP send's would wait or get stuck ? 
  // If so we cannot use send_json instead improve the logic here -- kmuriki
  
  fprintf(stderr,"About to write on FD - %d\n",fd);
 
  json_object *jobj;
  jobj = json_object_new_object();
  
  // send JSON string iff an application
  if(sock_data[fd].ctype == APPLICATION){
  	sqlite3_exec(db, sock_data[fd].sqlite_cmd, json_from_db2, jobj, NULL);
  
	// free the temporary buffer
  	// allocated for the sqlite_cmd
  	if(sock_data[fd].sqlite_cmd != NULL){
  	  free(sock_data[fd].sqlite_cmd);
  	}
  } else {
  // send the command to collector
  	json_object_object_add(jobj,"Command",json_object_new_string("Send Data"));
  }

  send_json(fd,jobj);
  json_object_put(jobj);
  //printf("send successful!\n");

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
  //fprintf(stderr, "Rx a string of size %d - %s\n",readbytes,rbuf);
  //fprintf(stderr, "Rx a string of size %d \n",readbytes);

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

     //printf("Len of the payload - %d, %s\n", app_h->len,app_d->payload);
 
     // plus 1 to store the NULL char
     sock_data[fd].accural_buf = (char *) malloc(app_h->len+1);
     strcpy(sock_data[fd].accural_buf,app_d->payload);
     sock_data[fd].r_payloadlen = app_h->len - strlen(sock_data[fd].accural_buf);
     //printf("strlen(sock_data[%d].accural_buf) = %d\n", fd, strlen(sock_data[fd].accural_buf));
  }

  if (sock_data[fd].r_payloadlen > 0) {
     //Still has more reading to do
    //printf("r_payloadlen = %d\n", sock_data[fd].r_payloadlen);
    return(0);
  }

  printf("Done reading totally\n");

  // added logical system for handling the three kinds of messages from TCP:
  // 1) Declaration of connection type
  // 2) An SQLite command from an application
  // 3) A JSON representation of wwmon_collector.c information
  if(strstr(sock_data[fd].accural_buf, "ctype"))
    {
      printf("case 0\n");
      int ctype;
      jobj = json_tokener_parse(sock_data[fd].accural_buf);
      ctype = json_object_get_int(json_object_object_get(jobj, "ctype"));
      sock_data[fd].ctype = ctype;
    }
  else if(strstr(sock_data[fd].accural_buf, "sqlite_cmd"))
    {
      //printf("case 1\n");
      jobj = json_tokener_parse(sock_data[fd].accural_buf);
      sock_data[fd].sqlite_cmd = malloc(sizeof(char)*MAX_SQL_SIZE); 
      strcpy(sock_data[fd].sqlite_cmd, json_object_get_string(json_object_object_get(jobj, "sqlite_cmd")));
    }
  else if(strstr(sock_data[fd].accural_buf, "JSON"))
    {

      //printf("case 2\n");
      // convert json_string to object
      jobj = json_tokener_parse(sock_data[fd].accural_buf);                                 
      json_parse_complete(jobj);
      // update database call                                                                                                                                  
      update_db2(jobj, db); // changed to update_db2
    }
  else 
    {
      printf("%s\n",sock_data[fd].accural_buf);
      jobj = json_tokener_parse(sock_data[fd].accural_buf);
      update_dbase(jobj, db);
    }  

  sock_data[fd].validinfo = 1;
  if(sock_data[fd].accural_buf != NULL){
    free(sock_data[fd].accural_buf);
  }
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

  sqlite3_exec(db, "select rowid,NodeName,key,value from wwstats", json_from_db2, json_db, NULL);

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
  // Register interest in a read on this socket.
  FD_SET(c, &rfds);
  
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

  // Get the database ready
  // Attempt to open database & check for failure
  if( rc = sqlite3_open("wwmon.db", &db)  ){
    fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
    exit(1);
  } else {
    printf("wwmon.db ready for reading and writing...\n");
  }

  // Prepare to accept clients
  FD_ZERO(&rfds);
  FD_ZERO(&wfds);

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
