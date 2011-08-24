//
// Copyright (c) 2001-2003 Gregory M. Kurtzer
// 
// Copyright (c) 2003-2011, The Regents of the University of California,
// through Lawrence Berkeley National Laboratory (subject to receipt of any
// required approvals from the U.S. Dept. of Energy).  All rights reserved.
//
// Contributed by Anthony Salgado & Krishna Muriki
// Warewulf Monitor (wwmon_collector.c)
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

#include "util.c"

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
  json_object *jstring;

  // Why malloc a know fixed size buffer --kmuriki
  char *buffer= malloc(sizeof(char)*MAXPKTSIZE);

  apphdr *app_h = (apphdr *) buffer;
  appdata *app_d = (appdata *) (buffer + sizeof(apphdr));

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

  // I don't think we need to malloc jobj
  json_object *jobj;// = malloc(sizeof(json_object *));

  // tell aggregator that I am a collector
  jobj = json_object_new_object();
  json_object_object_add(jobj, "ctype", json_object_new_int(COLLECTOR));

/*
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

*/

  int bytes_left;
  sendall_repeat(sock, buffer, app_h, app_d, jobj);

  
  while(1) {
    
    /* Edit here was to implement a while loop receive
       that we discussed before. */ 
/*
    char *rbuf = malloc(sizeof(char)*MAXPKTSIZE);
    if ((bytes_read=recv(sock, buffer, MAXPKTSIZE-1, 0)) == -1) {
      perror("recv");
      exit(1);
    }

    bytes_left = app_h->len;
    while(bytes_read < bytes_left){
      if((bytes_read += recv(sock, buffer, MAXPKTSIZE-1,0)) == -1){
	perror("recv");
	exit(1);
      }
      strcat(app_d->payload, rbuf);
    }

    free(rbuf);

    buffer[bytes_read] = '\0';
*/
    recvall(sock, buffer, app_h, app_d);
    
    array_list *requested_keys = array_list_new(NULL);
    array_list_add(requested_keys, "MemTotal");
    array_list_add(requested_keys, "MemFree");
    array_list_add(requested_keys, "SwapTotal");
    array_list_add(requested_keys, "SwapFree");

    jobj = fast_data_parser("/proc/meminfo", requested_keys, array_list_length(requested_keys));
    
    gethostname(local_sysname,sizeof(local_sysname));
    jstring = json_object_new_string(local_sysname);
    json_object_object_add(jobj,"NodeName",jstring);
    json_object_object_add(jobj, "cpu_util", (json_object *)json_object_new_double(get_cpu_util()));
    json_object_object_add(jobj, "JSON", (json_object *) json_object_new_string(json_object_to_json_string(jobj)));

    timer=time(NULL);
    date=asctime(localtime(&timer));
    json_object_object_add(jobj,"TimeStamp",(json_object *) json_object_new_string(chop(date)));


    /* This new section of code 'transposes' the current json_object
       such that it can be formatted as identified by the key/value it holds
       and is stuffed into another json_object as if it were nested. */

    json_object *j2 = json_object_new_object();
    json_object_object_foreach(jobj, key, value){
      json_object *tmp = json_object_new_object();
      json_object_object_add(tmp, "NodeName", jstring);
      json_object_object_add(tmp, "key", (json_object *) json_object_new_string(key));
      json_object_object_add(tmp, "value", value);
      json_object_object_add(j2, key, tmp);
    }

    json_parse(j2); // see output of this line of code for clarification    
    jobj = j2; // send the 'transposed' json_object over the socket. 

/*
    json_len = (int )strlen(json_object_to_json_string(jobj));
    record = (char *)malloc(json_len+1); //plus 1 for the null character
    strcpy(record,json_object_to_json_string(jobj));
    
    bytes_read = 0; //bytes read from the record so far and sent
    bytes_left = json_len;
    
    /* should we make this a function? */
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
*/

    sendall_repeat(sock, buffer, app_h, app_d, jobj);
    json_object_put(j2); // freeing j2


    sleep(10);
  }

  json_object_put(jstring);
  json_object_put(jobj);

  close(sock);
  return 0;
}
