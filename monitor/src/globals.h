/*
 * Copyright (c) 2001-2003 Gregory M. Kurtzer
 * 
 * Copyright (c) 2003-2011, The Regents of the University of California,
 * through Lawrence Berkeley National Laboratory (subject to receipt of any
 * required approvals from the U.S. Dept. of Energy).  All rights reserved.
 *
 * Contributed by Anthony Salgado & Krishna Muriki
 * Warewulf Monitor (globals.h)
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

#include <sys/utsname.h>

#define MAXPKTSIZE 10024   // PKTSIZE Should be DATASIZE + sizeof(apphdr);
#define MAXDATASIZE 10020

#define MAX_IPADDR_LEN   50
#define MAX_NODENAME_LEN  50
#define MAX_SQL_SIZE 1024

#define SQLITE_DB_FNAME "wwmon.db"
#define SQLITE_DB_TB1NAME "datastore"
#define SQLITE_DB_TB2NAME "lookups"

#define UNKNOWN 0
#define COLLECTOR 1
#define APPLICATION 2

typedef struct private_info_of_any_socket {

        // Variables used by all sockets
        int     ctype;  // connection type
        int     r_payloadlen; // Remaining payload length that needs to be read

	char    *accural_buf;
        char    *sqlite_cmd;

        char remote_sock_ipaddr[MAX_IPADDR_LEN];

	// Now all the variables for ctype - 1 (the collector socket)
	// Now all the variables for ctype - 2 (the app socket)

} sockdata;

typedef struct application_hdr {

	int 	len; //To record the actual size of the payload
        time_t 	timestamp;
	char    nodename[MAX_NODENAME_LEN];

} apphdr;

typedef struct application_data {

	char    payload[MAXDATASIZE];

} appdata; 	

// Possible states of the sockets

#define STATEID1    0
#define STATEID2    1
#define STATEID3    2
#define STATEID4    3
#define STATEID5    4
#define STATEID6    5
#define STATEID7    6

//Global structure array with values of each socket
sockdata sock_data[FD_SETSIZE];
//Global Database to hold data of each socket
static sqlite3 *db; // database pointer

fd_set rfds, wfds;

