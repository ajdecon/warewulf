/*
** talker.c -- a datagram "client" demo
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#include "util.c"

#define MYPORT 5000    // the port users will be connecting to
#define MAXBUFLEN 6710784

int main(int argc, char *argv[])
{
    int sockfd;
    struct sockaddr_in their_addr; // connector's address information
    struct hostent *he;
    int addr_len, numbytes;
    char buf[MAXBUFLEN];

    if (argc != 3){
        fprintf(stderr,"Usage: %s aggregator_hostname port\n",argv[0]);
        exit(1);
    }

    if ((he=gethostbyname(argv[1])) == NULL) {  // get the host info
        perror("gethostbyname");
        exit(1);
    }

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        perror("socket");
        exit(1);
    }

    their_addr.sin_family = AF_INET;     // host byte order
    their_addr.sin_port = htons(atoi(argv[2])); // short, network byte order
    their_addr.sin_addr = *((struct in_addr *)he->h_addr);
    memset(&(their_addr.sin_zero), '\0', 8);  // zero the rest of the struct

    strcpy(buf,"SendData");
    if ((numbytes=sendto(sockfd, buf, strlen(buf), 0,
                     (struct sockaddr *)&their_addr, sizeof(struct sockaddr))) == -1) {
        perror("sendto");
        exit(1);
    }

    addr_len = sizeof(struct sockaddr);
    if ((numbytes=recvfrom(sockfd, buf, MAXBUFLEN-1, 0,
                     (struct sockaddr *)&their_addr, &addr_len)) == -1) {
        perror("recvfrom");
        exit(1);
    }

    buf[numbytes] = '\0';

    printf("\n=========SYSTEM STATISTICS=========\n\n");
    json_parse_complete(json_tokener_parse(buf));
    printf("\n===================================\n\n");

    close(sockfd);

    return 0;
}
