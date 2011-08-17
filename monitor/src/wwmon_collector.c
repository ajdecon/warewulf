//
// Warewulf Monitor Collector (wwmon_collector.c)
//
// Copyright(c) 2011 Anthony Salgado & Krishna Muriki
//

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

#include "globals.h"
#include "util.c"

int main(int argc, char *argv[]){
  
  char *date;
  time_t timer;

  int sock, bytes_read, addr_len = sizeof(struct sockaddr);
  struct sockaddr_in server_addr;
  struct hostent *host;

  char local_sysname[MAX_SYSNAME_LEN];
  json_object *jstring;

  char buffer[MAXPKTSIZE];

  apphdr *app_h = (apphdr *) buffer;
  appdata *app_d = (appdata *) (buffer + sizeof(apphdr));

  if (argc != 3) {
      fprintf(stderr,"Usage: %s aggregator_hostname [port] \n", argv[0]);
      exit(1);
  }

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

  json_object *jobj = malloc(sizeof(json_object *));
  memset(jobj, 0, sizeof(json_object *));
  memset(buffer, 0, sizeof(buffer));

while(1) {
  strcpy(buffer,"");
  if ((bytes_read=recv(sock, buffer, MAXPKTSIZE-1, 0)) == -1) {
      perror("recv");
      exit(1);
  }
  buffer[bytes_read] = '\0';
  
  array_list *requested_keys = array_list_new(NULL);
  //printf("Adding to requests: %s\n", buffer);
  array_list_add(requested_keys, "MemTotal");
  array_list_add(requested_keys, "MemFree");
  array_list_add(requested_keys, "SwapTotal");
  array_list_add(requested_keys, "SwapFree");
  array_list_print(requested_keys);
  jobj = fast_data_parser("/proc/meminfo", requested_keys, array_list_length(requested_keys));

  gethostname(local_sysname,sizeof(local_sysname));
  jstring = json_object_new_string(local_sysname);
  json_object_object_add(jobj,"NodeName",jstring);

  timer=time(NULL);
  date=asctime(localtime(&timer));
  json_object_object_add(jobj,"TimeStamp",(json_object *) json_object_new_string(chop(date)));

  json_parse(jobj);

  int json_len, bytes_left, buffer_len, bytestocopy;
  char *record;

  json_len = (int )strlen(json_object_to_json_string(jobj));
  record = (char *)malloc(json_len+1); //plus 1 for the null character
  strcpy(record,json_object_to_json_string(jobj));

  bytes_read = 0; //bytes read from the record so far and sent
  bytes_left = json_len;
  
  while(bytes_read < json_len) 
  {
     buffer_len = 0;

     if(bytes_read == 0) {
        app_h->len = json_len;
        
        bytestocopy = (MAXDATASIZE < bytes_left ? MAXDATASIZE : bytes_left);
        strncpy(app_d->payload,record,bytestocopy);

        buffer_len = sizeof(apphdr); // to accomodate the header size
     } else {
        bytestocopy = (MAXPKTSIZE < bytes_left ? MAXPKTSIZE : bytes_left);
        strncpy(buffer,record+bytes_read,bytestocopy);
     }

     buffer_len += bytestocopy;

     printf("Sending data ..\n");
     sendall(sock, buffer, buffer_len);

     bytes_read += bytestocopy;
     bytes_left -= bytestocopy;
  }
  free(record);
  sleep(10);
}
 
  free(jobj); 

  close(sock);
  return 0;
}

