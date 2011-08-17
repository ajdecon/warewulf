
#define MAXPKTSIZE 20   // PKTSIZE Should be DATASIZE + sizeof(apphdr);
#define MAXDATASIZE 16

#define MAX_IPADDR_LEN   50
#define MAX_SYSNAME_LEN  50

typedef struct private_info_of_any_socket {

	// Variables used by all sockets.
        int     validinfo;    // 1 if this socket has a connection and valid info
                              // 0 is this socket has not connection and valid info
	char    *accural_buf; //
        int     r_payloadlen; // Remaining payload length that needs to be read

	int     type;	// type of the socket - 0 for (Collector)
	        	// type of the socket - 1 for (Application like wwstats)

        char    remote_sock_ipaddr[MAX_IPADDR_LEN];

	// Now all the variables for type - 1 (the collector socket)
	// Now all the variables for type - 0 (the app socket)


} sockdata;

typedef struct application_header {

	int 	len; //To record the size of the payload

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

