/*
 * Copyright (c) 2001-2003 Gregory M. Kurtzer
 * 
 * Copyright (c) 2003-2011, The Regents of the University of California,
 * through Lawrence Berkeley National Laboratory (subject to receipt of any
 * required approvals from the U.S. Dept. of Energy).  All rights reserved.
 *
 * Contributed by Anthony Salgado & Krishna Muriki
 * Warewulf Monitor (wwmon_collector.c)
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
#include <time.h>

#include "util.c"
#include "getstats.c"

int main(int argc, char *argv[]){
  
  if (argc != 3) {
      fprintf(stderr,"Usage: %s aggregator_hostname [port] \n", argv[0]);
      exit(1);
  }

  char *date;
  time_t timer;
  int sock, bytes_read, addr_len = sizeof(struct sockaddr);
  struct sockaddr_in server_addr;
  struct hostent *host;

  char local_sysname[MAX_SYSNAME_LEN];
  //json_object *jstring;

  if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
  {
    perror("socket");
    exit(1);
  }

  if ((host=gethostbyname(argv[1])) == NULL) {  // get the host info 
      perror("gethostbyname");
      exit(1);
  }

  server_addr.sin_family = AF_INET;
  server_addr.sin_port = htons(atoi(argv[2]));
  server_addr.sin_addr = *((struct in_addr *)host->h_addr);
  bzero(&(server_addr.sin_zero),8);

  printf("\nSocket opened\n");

  if (connect(sock, (struct sockaddr *)&server_addr, sizeof(struct sockaddr)) == -1) {
      perror("connect");
      exit(1);
  }

  json_object *jobj;

  // tell aggregator that I am a collector
  jobj = json_object_new_object();
  json_object_object_add(jobj, "ctype", json_object_new_int(COLLECTOR));

  printf("%s\n", json_object_to_json_string(jobj));
  send_json(sock, jobj);
 
  json_object_put(jobj);

  gethostname(local_sysname,sizeof(local_sysname));

  char *rbuf;
  while(1) {

    rbuf = recvall(sock);
    printf("Received - %s\n",rbuf);
    free(rbuf);

    jobj = json_object_new_object();

    get_sysinfo(jobj);
    get_cpu_info(jobj); 
    get_uname(jobj);
    get_cpu_util(jobj);
    get_mem_stats(jobj);
    get_load_avg(jobj); 
    get_net_stats(jobj);
    get_node_status(jobj);


    printf("%s\n", json_object_to_json_string(jobj));
    send_json(sock,jobj);

    json_object_put(jobj);

    sleep(1);
  }

  close(sock);
  return 0;
}
