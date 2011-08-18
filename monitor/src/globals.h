

/* Possible states of the sockets
 * STATEID1    - 0
 * STATEID1    - 1
 * STATEID1    - 2
 * STATEID1    - 3
 * STATEID1    - 4
 * STATEID1    - 5
 */

#define STATEID1    0
#define STATEID2    1
#define STATEID3    2
#define STATEID4    3
#define STATEID5    4
#define STATEID6    5
#define STATEID7    6

#define MAX_IPADDR_LEN   50
#define MAX_SYSNAME_LEN  50

#define MAXPKTSIZE 9604   // PKTSIZE Should be DATASIZE + sizeof(apphdr);
#define MAXDATASIZE 9600

#define COLLECTOR 0
#define APPLICATION 1
#define MAX_SQL_SIZE 1024

/* The two types of sockets which are possible and can 
   enter into the read interest or write interest sets*/

typedef struct private_info_of_any_socket {

        int     validinfo;  // 1 if this socket has a connection and valid info
                            // 0 is this socket has not connection and valid info
	char    *accural_buf;

        int     r_payloadlen; // Remaining payload length that needs to be read

	int	type;	// type of the socket - 0 for (server)	
			// type of the socket - 1 for (client)
  
        int     ctype;  // connection type, if collector: ctype = COLLECTOR
                        // connection type, if wwstats: ctype = WWSTATS
	// Now all the variables for type - 0 (the server socket)

        char    *sqlite_cmd;

	// Variables used by both types of sockets.

        char remote_sock_ipaddr[MAX_IPADDR_LEN];

	// Now all the variables for type - 1 (the client socket)


} myst2;

typedef struct app_hdr {

	int 	len; //size of the packet

} apphdr;

typedef struct app_data {

	char    payload[MAXDATASIZE];

} appdata; 	

