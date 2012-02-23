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

#include "util.c"

int
json_from_db(void *void_json, int ncolumns, char **col_values, char **col_names)
{
  int i;
  json_object *json_db = (json_object *) void_json;

  int nodename_idx = -1, jsonblob_idx = -1;
  // Find the indexes 
  for( i=0; i<ncolumns; i++ ) {
    if(strcmp(col_names[i],"nodename") == 0) nodename_idx = i;
    if(strcmp(col_names[i],"jsonblob") == 0) jsonblob_idx = i;
  }

  if( nodename_idx < 0 ) {
    // There are no nodes to be returned just return.
    return 0;
  }

  json_object_object_add(json_db, col_values[nodename_idx], json_object_new_string(col_values[jsonblob_idx]));
  int json_ct = get_int_from_json(json_db, "JSON_CT");
  json_ct++;
  json_object_object_add(json_db,"JSON_CT",json_object_new_int(json_ct));

  return 0;
}

void
update_dbase(time_t TimeStamp, char *NodeName, json_object *jobj)
{
  //printf("NodeName - %s, TimeStamp - %ld\n", NodeName, TimeStamp);

  // Now check if the NodeName exists in the table 
  // If so compare the timestamp values and decide what to do.

  int DBTimeStamp = -1;
  if ( (DBTimeStamp = NodeTS_fromDB(NodeName)) == -1 ) {
    insert_json(NodeName, TimeStamp, jobj);
    int blobid = -1;
    blobid = NodeBID_fromDB(NodeName);
    insertLookups(blobid, jobj);

  } else if ( DBTimeStamp < TimeStamp ) {
    update_json(NodeName, TimeStamp, jobj);
    int blobid = -1;
    blobid = NodeBID_fromDB(NodeName);
    updateLookups(blobid, jobj);

  } else if (DBTimeStamp > TimeStamp ) {
    printf("DB has more current record - %d... Skipping update\n",DBTimeStamp);
  }
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

  sqlite3_exec(db, "select rowid,NodeName,key,value from wwstats", json_from_db, json_db, NULL);

  // send json_object over socket to wwstats
  if ((numbytes=sendto(fd, json_object_to_json_string(json_db), strlen(json_object_to_json_string(json_db)), 0,
		       (struct sockaddr *)&their_addr, sizeof(struct sockaddr))) == -1) {
    perror("sendto");
  }  
  printf("sent %d bytes to %s\n", numbytes, inet_ntoa(their_addr.sin_addr));

  return;
}

int
writeHandler(int fd) 
{
  // Should we assume that even the TCP send's cannot be made when we want ?
  // In other words is it possible that TCP send's would wait or get stuck ? 
  // If so we cannot use send_json instead improve the logic here -- kmuriki
  
  fprintf(stderr,"About to write on FD - %d, type - %d\n",fd,sock_data[fd].ctype);
 
  char payload[1024];
  
  json_object *jobj;
  jobj = json_object_new_object();

  if(sock_data[fd].ctype == UNKNOWN) {
      strcpy(payload,"Send Type");
      json_object_object_add(jobj,"COMMAND",json_object_new_string(payload));
  } else if(sock_data[fd].ctype == COLLECTOR) {
      strcpy(payload,"Send Data");
      json_object_object_add(jobj,"COMMAND",json_object_new_string(payload));
  } else if(sock_data[fd].ctype == APPLICATION) {
      if(sock_data[fd].sqlite_cmd != NULL){
          printf("SQL cmd - %s\n", sock_data[fd].sqlite_cmd);
          json_object_object_add(jobj,"JSON_CT",json_object_new_int(0));
          sqlite3_exec(db, sock_data[fd].sqlite_cmd, json_from_db, jobj, NULL);
          //TODO : Check the sql command return values and if failure or no return send proper message to the App
          printf("JSON - %s\n",json_object_to_json_string(jobj));
  	  free(sock_data[fd].sqlite_cmd);
      } else {
          strcpy(payload,"Send SQL query");
          json_object_object_add(jobj,"COMMAND",json_object_new_string(payload));
      }
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
  fprintf(stderr,"About to read on FD - %d, type - %d\n",fd,sock_data[fd].ctype);

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

  printf("Done reading totally, now processing the received data packet\n");

  if(sock_data[fd].ctype == UNKNOWN) {
	int ctype;
	ctype = get_int_from_json(json_tokener_parse(sock_data[fd].accural_buf),"CONN_TYPE");
	if(ctype == -1) {
	  printf("Not able to determine type\n");
	} else {
	  sock_data[fd].ctype = ctype;
	  //printf("Conn type - %d on sock - %d\n",ctype, fd);
	}
   } else if(sock_data[fd].ctype == COLLECTOR) {

      //printf("%s\n",sock_data[fd].accural_buf);
      apphdr *app_h = (apphdr *) rbuf;
      jobj = json_tokener_parse(sock_data[fd].accural_buf);
      update_dbase(app_h->timestamp,app_h->nodename,jobj);
      json_object_put(jobj);

   } else if(sock_data[fd].ctype == APPLICATION) {

      jobj = json_tokener_parse(sock_data[fd].accural_buf);
      sock_data[fd].sqlite_cmd = malloc(MAX_SQL_SIZE); 
      strcpy(sock_data[fd].sqlite_cmd,"select nodename,jsonblob from ");
      strcat(sock_data[fd].sqlite_cmd,SQLITE_DB_TB1NAME);
      strcat(sock_data[fd].sqlite_cmd," left join ");
      strcat(sock_data[fd].sqlite_cmd,SQLITE_DB_TB2NAME);
      strcat(sock_data[fd].sqlite_cmd," on ");
      strcat(sock_data[fd].sqlite_cmd,SQLITE_DB_TB1NAME);
      strcat(sock_data[fd].sqlite_cmd,".rowid = ");
      strcat(sock_data[fd].sqlite_cmd,SQLITE_DB_TB2NAME);
      strcat(sock_data[fd].sqlite_cmd,".blobid where ");
      int len = strlen(sock_data[fd].sqlite_cmd);
      strcat(sock_data[fd].sqlite_cmd, json_object_get_string(json_object_object_get(jobj, "sqlite_cmd")));
      if (len == strlen(sock_data[fd].sqlite_cmd)) {
	//App sent an empty SQL command so we need to return all JSONs we have
	strcpy(sock_data[fd].sqlite_cmd,"select nodename,jsonblob from ");
	strcat(sock_data[fd].sqlite_cmd,SQLITE_DB_TB1NAME);
      }
   } 

  if(sock_data[fd].accural_buf != NULL){
    free(sock_data[fd].accural_buf);
  }
  FD_CLR(fd, &rfds);
  FD_SET(fd, &wfds);
  return(0);
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

  // Initialize all the variables
  // Connection type unknown at this time
  sock_data[c].ctype = UNKNOWN;
  sock_data[c].r_payloadlen = 0;
  sock_data[c].sqlite_cmd = NULL;
  sock_data[c].accural_buf = NULL;

  // Register interest in a read on this socket to know more about the connection.
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
  if( rc = sqlite3_open(SQLITE_DB_FNAME, &db)  ){
    fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
    exit(1);
  } else {
  // Now check & create tables if required 
    createTable(db,SQLITE_DB_TB1NAME);
    createTable(db,SQLITE_DB_TB2NAME);
    printf("Database ready for reading and writing...\n");
  }

  // Prepare to accept clients
  FD_ZERO(&rfds);
  FD_ZERO(&wfds);

  // Open TCP (SOCK_STREAM) & UDP (SOCK_DGRAM) sockets, bind to the port 
  // given and listen on TCP sock for connections
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
