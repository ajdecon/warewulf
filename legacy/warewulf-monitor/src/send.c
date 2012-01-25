/*
 * Copyright (c) 2004-2006, Greg M. Kurtzer <gmk@runlevelzero.net>. All
 * rights reserved.
 *
 * Copyright (c) 2003, The Regents of the University of California, through
 * Lawrence Berkeley National Laboratory (subject to receipt of any
 * required approvals from the U.S. Dept. of Energy).  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * The GNU GPL Document can be found at:
 * http://www.gnu.org/copyleft/gpl.html
 *
 * Written By Greg Kurtzer <gmk@runlevelzero.net> originally for the Warewulf
 * Cluster toolkit project (http://warewulf-cluster.org/) and now for
 * Perceus (http://www.perceus.org/).
 *
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <syslog.h>

#include "config.h"

unsigned int udp_send(char *hostname, char *data) {
	int sd, rc;
	//struct sockaddr_in server;
	//struct hostent *server_data;
	struct sockaddr_in cliAddr, remoteServAddr;
	static struct hostent *h = NULL;

    if (h == NULL) {
        h = gethostbyname(hostname);
        if (h == NULL) {
            syslog(LOG_ERR, "Unknown host \"%s\"", hostname);
            return 1;
        }
	}

//	printf("SEND: UDP 'packet' to '%s' (IP : %s) \n", h->h_name,
//		inet_ntoa(*(struct in_addr *)h->h_addr_list[0]));

	remoteServAddr.sin_family = h->h_addrtype;

	memcpy((char *) &remoteServAddr.sin_addr.s_addr, 
		h->h_addr_list[0], h->h_length);
	remoteServAddr.sin_port = htons(REMOTE_SERVER_PORT);

	sd = socket(AF_INET,SOCK_DGRAM,0);
	if (sd < 0) {
		syslog(LOG_ERR, "Cannot open socket -- %s", strerror(errno));
		return 2;
	}

	cliAddr.sin_family = AF_INET;
	cliAddr.sin_addr.s_addr = htonl(INADDR_ANY);
	cliAddr.sin_port = htons(0);

	rc = bind(sd, (struct sockaddr *) &cliAddr, sizeof(cliAddr));
	if (rc < 0) {
		syslog(LOG_ERR, "Cannot bind port -- %s", strerror(errno));
		return 3;
	}

	rc = sendto(sd, data, strlen(data), 0,
		(struct sockaddr *) &remoteServAddr, 
		sizeof(remoteServAddr));

	if (rc < 0) {
		syslog(LOG_ERR, "Error sending data -- %s", strerror(errno));
		return 4;
	}

	close(sd);
	return 0;
}
