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
#include <ctype.h>
#include <json/json.h>
#include <sqlite3.h>

#include "getstats.h"
#include "util.h"
#include "config.h"

#define PROGRAM_TYPE COLLECTOR

int main(int argc, char *argv[]){
  
  if (argc != 3) {
      fprintf(stderr,"Usage: %s aggregator_hostname [port] \n", argv[0]);
      exit(1);
  }

  int sock; 

  if((sock=setup_ConnectSocket(argv[1], atoi(argv[2])))<0)
    exit(1);

  registerConntype(sock,PROGRAM_TYPE);
  
  time_t timer;
  char *rbuf;
  json_object *jobj;

  while(1) {

    rbuf = recvall(sock);
    printf("Received - %s\n",rbuf);
    free(rbuf);

    jobj = json_object_new_object();

    timer = time(NULL);
    json_object_object_add(jobj,"TIMESTAMP",json_object_new_int(timer));

    get_sysinfo(jobj);    // PROCS, UPTIME
    get_cpu_info(jobj);   // CPUCOUNT, CPUCLOCK, CPUMODEL
    get_uname(jobj);      // SYSNAME, NODENAME, RELEASE, VERSION, MACHINE
    get_cpu_util(jobj);   // CPUUTIL
    get_mem_stats(jobj);  // MEMTOTAL, MEMAVAIL, MEMUSED, MEMPERCENT, SWAPTOTAL, SWAPFREE, SWAPUSED, SWAPPERCENT
    get_load_avg(jobj);   // LOADAVG
    get_net_stats(jobj);  // NETTRANSMIT, NETRECEIVE
    get_node_status(jobj);// NODESTATUS

    printf("%s\n", json_object_to_json_string(jobj));
    send_json(sock,jobj);

    json_object_put(jobj);

    sleep(60);
  }

  close(sock);
  return 0;
}
