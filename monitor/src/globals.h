//
// Copyright (c) 2001-2003 Gregory M. Kurtzer
// 
// Copyright (c) 2003-2011, The Regents of the University of California,
// through Lawrence Berkeley National Laboratory (subject to receipt of any
// required approvals from the U.S. Dept. of Energy).  All rights reserved.
//
// Contributed by Anthony Salgado & Krishna Muriki
// Warewulf Monitor (globals.h)
//

#define MAXPKTSIZE 10024   // PKTSIZE Should be DATASIZE + sizeof(apphdr);
#define MAXDATASIZE 10020

#define MAX_IPADDR_LEN   50
#define MAX_SYSNAME_LEN  50
#define MAX_SQL_SIZE 1024

#define COLLECTOR 0
#define APPLICATION 1

typedef struct private_info_of_any_socket {

        // Variables used by all sockets
        int     validinfo;  // 1 if this socket has a connection and valid info
                            // 0 is this socket has not connection and valid info
	char    *accural_buf;
        int     r_payloadlen; // Remaining payload length that needs to be read

        int     ctype;  // connection type, if collector: ctype = COLLECTOR
                        // connection type, if wwstats: ctype = WWSTATS

        char remote_sock_ipaddr[MAX_IPADDR_LEN];
        char    *sqlite_cmd;

	// Now all the variables for ctype - 0 (the collector socket)
	// Now all the variables for type - 1  (the app socket)

} sockdata;

typedef struct application_hdr {

	int 	len; //To record the actual size of the payload

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

