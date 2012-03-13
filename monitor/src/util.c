/*
 * Copyright (c) 2001-2003 Gregory M. Kurtzer
 * 
 * Copyright (c) 2003-2011, The Regents of the University of California,
 * through Lawrence Berkeley National Laboratory (subject to receipt of any
 * required approvals from the U.S. Dept. of Energy).  All rights reserved.
 *
 * Contributed by Anthony Salgado & Krishna Muriki
 * Warewulf Monitor (util.c)
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

#include "globals.h"
#include "util.h"

/* Any forward declarations */
static int
nothing_todo(void *NotUsed, int argc, char **argv, char **azColName)
{
  int i;
  for(i=0; i<argc; i++){
    printf("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
  }
  //printf("\n");
  return 0;
}

static int
getint_callback(void *void_int, int argc, char **argv, char **azColName)
{
  int *int_value = (int *)void_int;
  *int_value = atoi(argv[argc-1]);

  return 0;
}

void
insertLookups(int blobid, json_object *jobj, sqlite3 *db) 
{

  //Can we assume 64 bits for rowid ?
  char blobID[65];
  char *sqlite_cmd = malloc(MAX_SQL_SIZE);
  enum json_type type;

  json_object_object_foreach(jobj, key, value){
    strcpy(sqlite_cmd, "insert into lookups(blobid, key, value) values ('");
    sprintf(blobID,"%d",blobid);
    strcat(sqlite_cmd, blobID);
    strcat(sqlite_cmd, "','");
 
    strcat(sqlite_cmd,key);
    strcat(sqlite_cmd, "',");

    // Clean the int logic
    // Can we assume 64 bits for all ints ?
    char vals[65];
    type = json_object_get_type(value);
    switch(type) {
      case json_type_int:
        sprintf(vals, "%d",json_object_get_int(value));
        strcat(sqlite_cmd,vals);
        break;
      case json_type_string:
	strcat(sqlite_cmd, "'");
        strcat(sqlite_cmd, json_object_get_string(value));
	strcat(sqlite_cmd, "'");
        break;
    }
    strcat(sqlite_cmd, ")");

    //printf("IL SQL CMD - %s\n",sqlite_cmd);
    char *emsg = 0;
    int rc = sqlite3_exec(db, sqlite_cmd, nothing_todo, 0, &emsg);
    if( rc!=SQLITE_OK ){
      fprintf(stderr, "SQL error: %s\n", emsg);
      sqlite3_free(emsg);
    }
  } // end json_foreach
  free(sqlite_cmd);
}

void
updateLookups(int blobid, json_object *jobj, sqlite3 *db) 
{

  //Can we assume 64 bits for rowid ?
  char blobID[65];
  char *sqlite_cmd = malloc(MAX_SQL_SIZE);
  enum json_type type;

  json_object_object_foreach(jobj, key, value){
    strcpy(sqlite_cmd, "update lookups set value=");
    // Clean the int logic
    // Can we assume 64 bits for all ints ?
    char vals[65];
    type = json_object_get_type(value);
    switch(type) {
      case json_type_int:
        sprintf(vals, "%d",json_object_get_int(value));
        strcat(sqlite_cmd,vals);
        break;
      case json_type_string:
        strcat(sqlite_cmd, "'");
        strcat(sqlite_cmd, json_object_get_string(value));
        strcat(sqlite_cmd, "'");
        break;
    }
    strcat(sqlite_cmd, " where key='");
    strcat(sqlite_cmd,key);
    strcat(sqlite_cmd, "' and blobid='");
    sprintf(blobID,"%d",blobid);
    strcat(sqlite_cmd, blobID);
    strcat(sqlite_cmd, "'");

    printf("UL SQL CMD - %s\n",sqlite_cmd);
    char *emsg = 0;
    int rc = sqlite3_exec(db, sqlite_cmd, nothing_todo, 0, &emsg);
    if( rc!=SQLITE_OK ){
      fprintf(stderr, "SQL error: %s\n", emsg);
      sqlite3_free(emsg);
    }
  } // end json_foreach
  free(sqlite_cmd);
}

void
fillLookups(int blobid, json_object *jobj, sqlite3 *db) 
{

  //Can we assume 64 bits for rowid ?
  char blobID[65];
  char *sqlite_cmd = malloc(MAX_SQL_SIZE);
  enum json_type type;

  json_object_object_foreach(jobj, key, value){
   // What is the correct SQL to use ?
   strcpy(sqlite_cmd, "insert or replace into lookups(blobid, key, value) values ('");
   sprintf(blobID,"%d",blobid);
   strcat(sqlite_cmd, blobID);
   strcat(sqlite_cmd, "','");

   if(strcmp(key,"NODENAME")!=0 && strcmp(key,"TIMESTAMP")!=0) {

   	strcat(sqlite_cmd,key);
	strcat(sqlite_cmd, "','");

    	// Clean the int logic
        // Can we assume 64 bits for all ints ?
    	char vals[65];
    	type = json_object_get_type(value);
    	switch(type) {
        	case json_type_int:
                	sprintf(vals, "%d",json_object_get_int(value));
                	strcat(sqlite_cmd,vals);
                	break;
        	case json_type_string:
                	strcat(sqlite_cmd, json_object_get_string(value));
                	break;
    	}
    	strcat(sqlite_cmd, "')");

    //printf("SQL CMD - %s\n",sqlite_cmd);
    char *emsg = 0;
    int rc = sqlite3_exec(db, sqlite_cmd, nothing_todo, 0, &emsg);
    if( rc!=SQLITE_OK ){
      fprintf(stderr, "SQL error: %s\n", emsg);
      sqlite3_free(emsg);
    }

    } // end if
   } // end json_foreach

   free(sqlite_cmd);
}

void
insert_json(char *nodename, time_t timestamp, json_object *jobj, sqlite3 *db)
{

  char TimeStamp[11];
  char *sqlcmd = malloc(MAX_SQL_SIZE);

  strcpy(sqlcmd,"insert into ");
  strcat(sqlcmd,SQLITE_DB_TB1NAME);
  strcat(sqlcmd,"(jsonblob, timestamp, nodename) values('");
  strcat(sqlcmd,json_object_to_json_string(jobj));
  strcat(sqlcmd,"','");
  sprintf(TimeStamp,"%d",timestamp);
  strcat(sqlcmd,TimeStamp);
  strcat(sqlcmd,"','");
  strcat(sqlcmd,nodename);
  strcat(sqlcmd,"')");

  //printf("IJ CMD - %s\n",sqlcmd);
  int rc; char *emsg = 0;
  if( (rc = sqlite3_exec(db, sqlcmd, nothing_todo, 0, &emsg) != SQLITE_OK )) {
    fprintf(stderr, "SQL error: %s\n", emsg);
    sqlite3_free(emsg);
  }
  free(sqlcmd);

  return;
}

void
update_json(char *nodename, time_t timestamp, json_object *jobj, sqlite3 *db)
{
  char TimeStamp[11];
  char *sqlcmd = malloc(MAX_SQL_SIZE);

  strcpy(sqlcmd,"update ");
  strcat(sqlcmd,SQLITE_DB_TB1NAME);
  strcat(sqlcmd," set jsonblob='");
  strcat(sqlcmd,json_object_to_json_string(jobj));
  strcat(sqlcmd,"', ");
  strcat(sqlcmd,"timestamp='");
  sprintf(TimeStamp,"%d",timestamp);
  strcat(sqlcmd,TimeStamp);
  strcat(sqlcmd,"' where nodename='");
  strcat(sqlcmd,nodename);
  strcat(sqlcmd,"'");

  //printf("CMD - %s\n",sqlcmd);
  int rc; char *emsg = 0;
  if( (rc = sqlite3_exec(db, sqlcmd, nothing_todo, 0, &emsg) != SQLITE_OK )) {
    fprintf(stderr, "SQL error: %s\n", emsg);
    sqlite3_free(emsg);
  }
  free(sqlcmd);

  return;
}

void
insert_update_json(int dbts, char *nodename, time_t timestamp, json_object *jobj, sqlite3 *db)
{
  char TimeStamp[11];
  char *sqlcmd = malloc(MAX_SQL_SIZE);

  if ( dbts < 0 ) { // First time create a new row
    strcpy(sqlcmd,"insert into ");
  } else { // Not the first time no need to create a new row, just update
    strcpy(sqlcmd,"update ");
  }
  strcat(sqlcmd,SQLITE_DB_TB1NAME);

  if ( dbts < 0 ) {
    strcat(sqlcmd,"(jsonblob, timestamp, nodename) values('");
  } else {
    strcat(sqlcmd," set jsonblob='");
  }
  strcat(sqlcmd,json_object_to_json_string(jobj));
  strcat(sqlcmd,"', ");

  if ( dbts < 0 ) {
    strcat(sqlcmd,"'");
  } else {
    strcat(sqlcmd,"timestamp='");
  }
  sprintf(TimeStamp,"%d",timestamp);
  strcat(sqlcmd,TimeStamp);
  strcat(sqlcmd,"'");

  if ( dbts < 0 ) {
    strcat(sqlcmd,",");
  } else {
    strcat(sqlcmd," where nodename=");
  }
  strcat(sqlcmd,"'");
  strcat(sqlcmd,nodename);
  strcat(sqlcmd,"'");

  if ( dbts < 0 ) {
    strcat(sqlcmd,")");
  }
 
  //printf("CMD - %s\n",sqlcmd);
  int rc; char *emsg = 0;
  if( (rc = sqlite3_exec(db, sqlcmd, nothing_todo, 0, &emsg) != SQLITE_OK )) {
    fprintf(stderr, "SQL error: %s\n", emsg);
    sqlite3_free(emsg);
  }
  free(sqlcmd);

  return;
}

int 
NodeBID_fromDB(char *nodename, sqlite3 *db)
{
  int rc;
  char *emsg = 0;

  int blobid = -1;

  char *sqlcmd = malloc(MAX_SQL_SIZE);
  strcpy(sqlcmd,"select rowid from ");
  strcat(sqlcmd,SQLITE_DB_TB1NAME);
  strcat(sqlcmd," where nodename='");
  strcat(sqlcmd,nodename);
  strcat(sqlcmd,"'");
 
  //printf("BID CMD - %s\n",sqlcmd);
  if( (rc = sqlite3_exec(db, sqlcmd, getint_callback, &blobid , &emsg) != SQLITE_OK )) 
  {
    fprintf(stderr, "SQL error : %s\n", emsg);
    sqlite3_free(emsg);
  }
  free(sqlcmd);
  return(blobid);
}

int
NodeTS_fromDB(char *nodename, sqlite3 *db)
{
  int rc;
  char *emsg = 0;

  int timestamp = -1;

  char *sqlcmd = malloc(MAX_SQL_SIZE);
  strcpy(sqlcmd,"select timestamp from ");
  strcat(sqlcmd,SQLITE_DB_TB1NAME);
  strcat(sqlcmd," where nodename='");
  strcat(sqlcmd,nodename);
  strcat(sqlcmd,"'");

  //printf("TS CMD - %s\n",sqlcmd);
  if( (rc = sqlite3_exec(db, sqlcmd, getint_callback, &timestamp , &emsg) != SQLITE_OK )) 
  {
    fprintf(stderr, "SQL error : %s\n", emsg);
    sqlite3_free(emsg);
  }
  free(sqlcmd);
  return(timestamp);
}

char *
recvall(int sock)
{
  int count, r_payloadlen;

  char *rbuf = malloc(MAXPKTSIZE);

  apphdr *app_h = (apphdr *) rbuf;
  appdata *app_d = (appdata *) (rbuf + sizeof(apphdr));

  //block to receive the whole header
  if ((count=recv(sock, rbuf, sizeof(apphdr), MSG_WAITALL)) == -1) {
    perror("recv");
    exit(1);
  }
  //printf("app_h->len: %d\n", app_h->len);
  //printf("Received - %s\n",app_d->payload);

  char *buffer;
  // plus 1 to store the NULL char
  buffer = (char *) malloc (app_h->len+1);
  buffer[0] = '\0';

  r_payloadlen = app_h->len;

  int numtoread = MAXPKTSIZE-1;
  while(r_payloadlen > 0){
    if(r_payloadlen < MAXPKTSIZE-1) numtoread = r_payloadlen;
    if((count = recv(sock, rbuf, numtoread,0)) == -1){
      perror("recv");
      exit(1);
    }
    rbuf[count] = '\0';
    strcat(buffer, rbuf);
    r_payloadlen -= count;
  }
  free(rbuf);
  return buffer;
}

// To Handle any partial sends
int 
sendall(int s, char *buf, int total) 
{
  int sendbytes = 0;
  int bytesleft = total;
  int n = 0;

  while( sendbytes < total) {
        if( (n = send(s, buf+sendbytes, bytesleft, 0)) == -1) {
          perror("send");
          break;
        }
        sendbytes = sendbytes + n;
        bytesleft = bytesleft + n;
  }
  return n==-1? -1: 0;
}

int
send_json(int sock, json_object *jobj)
{

  time_t timer;
  timer = time(NULL);

  struct utsname unameinfo;
  uname(&unameinfo);

  char *buffer= malloc(sizeof(char)*MAXPKTSIZE);

  int  json_len, bytes_left, buffer_len, bytestocopy, bytes_read;
  char *json_str;

  json_len = (int) strlen(json_object_to_json_string(jobj)); // plus 1 for NULL char
  json_str = (char *) malloc(json_len+1);
  strcpy(json_str, json_object_to_json_string(jobj));

  bytes_read = 0;
  bytes_left = json_len;

  while(bytes_read < json_len)
    {
      buffer_len = 0;

      if(bytes_read == 0) {

        apphdr *app_h = (apphdr *) buffer;
        appdata *app_d = (appdata *) (buffer + sizeof(apphdr));

        app_h->len = json_len;
	app_h->timestamp = timer;
        strcpy(app_h->nodename,unameinfo.nodename);

        bytestocopy = (MAXDATASIZE < bytes_left ? MAXDATASIZE : bytes_left);
        strncpy(app_d->payload,json_str,bytestocopy);

        buffer_len = sizeof(apphdr); // to accomodate the header size
      } else {
        bytestocopy = (MAXPKTSIZE < bytes_left ? MAXPKTSIZE : bytes_left);
        strncpy(buffer,json_str+bytes_read,bytestocopy);
      }

      buffer_len += bytestocopy;

      printf("Sending data ..\n");
      sendall(sock, buffer, buffer_len);

      bytes_read += bytestocopy;
      bytes_left -= bytestocopy;
    }
  free(json_str);
  return json_len;
}

void
array_list_print(array_list *ls)
{
  printf("[");
  for(int i = 0; i < array_list_length(ls); i++){
    printf("%d: %s", i, array_list_get_idx(ls, i));
    if(i != array_list_length(ls) -1) printf(",");
  }
  printf(" ]\n");
}

/* void json_parse_complete(json_object *jobj); */

void
json_parse_complete(json_object *jobj){
  enum json_type type;
  json_object_object_foreach(jobj, key, val) {
    type = json_object_get_type(val);
    switch (type) {
    case json_type_string: 
      printf("%s : %s\n", key, json_object_get_string(val));
      break;
    case json_type_int: 
      printf("%s : %d\n", key, json_object_get_int(val));
      break;
    case json_type_object:
      printf("%s :\n",key);
      json_parse_complete(json_object_object_get(jobj, key));
      printf("\n");
      break;
    }
  }
} 

void
json_parse(json_object *jobj){
  json_object_object_foreach(jobj, key, value){
    printf("%s: %s\n", key, json_object_get_string(value));
  }
}

/*
Removes the new line character from the end of the 
string if it exists.
*/
char *chop(char *s){
    if(s[strlen(s)-1] == '\n') s[strlen(s)-1] = '\0';
    return s;
}


/*
More efficient version of file_parser. Instead of accessing a file 
number of keys times, opens a file only once and collects
data as it parses. Upon successful location of the key and value,
function places kv-pair in json_object whose pointer is the return
value.
*/
json_object *fast_data_parser(char *file_name, array_list *keys, int num_keys){
  FILE *fp;
  json_object *jobj = json_object_new_object();
  int i, keys_found = 0;
  if(fp = fopen(file_name, "r")){
    char *line = malloc(sizeof(char)*100);
    char *data = malloc(sizeof(char)*100);
    while(fgets(line, 100,fp)){
      for(i = 0; i < num_keys; i++){
	if(data = strstr(line, array_list_get_idx(keys, i))){
	  while(*data != ':') data++;
	  while(isspace(*data) || ispunct(*data)) data ++;
	  json_object_object_add(jobj, array_list_get_idx(keys, i), (json_object *) json_object_new_string(chop(data)));
	  keys_found += 1;
	  if(keys_found == num_keys) break; 
	}
      }
    }
    free(line);
    free(data);
    fclose(fp);
    return jobj;
  } else {
    printf("I/O ERROR: could not access file\n");
    return NULL;
  }
}

long
get_jiffs(cpu_data *cd)
{
  long total_jiffs, work_jiffs;
  int i=0;
  total_jiffs = 0;
  work_jiffs = 0;
  FILE *fp;
  if(fp = fopen("/proc/stat", "r")){
    char *line = malloc(sizeof(char)*100);
    char *data = malloc(sizeof(char)*100);
    while(fgets(line, 100, fp)){
      if(data = strstr(line, "cpu")){
	char * result = NULL;
	result = strtok(data, " ");
	while(result != NULL){
	  chop(result);
	  if(strcmp("cpu", result)){
	    if(i++ < 3) work_jiffs += atoi(result); // calculating work_jiffs
	    total_jiffs += atoi(result); // calculating total_jiffs
	  }
	  result = strtok(NULL, " ");
	}
      }
      i = 0; // reset i to get each cpu's work_jiffs added
    }
    free(line);
    free(data);
    fclose(fp);
    cd->tj = total_jiffs;
    cd->wj = work_jiffs;

    return 0;
  } else {
    printf("I/O ERROR: could not access file\n");
    return -1;
  }
}

/*
float
get_cpu_util_old()
{
  struct cpu_data *fin = malloc(sizeof(struct cpu_data *));
  struct cpu_data *init = malloc(sizeof(struct cpu_data *));
  get_jiffs(init);
  sleep(2);
  get_jiffs(fin);
  
  long work_diff = fin->wj - init->wj;
  long  total_diff = fin->tj - init->tj;
  
  free(fin);
  free(init);
  
  return (float) work_diff/total_diff*100;

}
*/

int
key_exists_in_json(json_object *jobj, char *kname) {
  json_object_object_foreach(jobj, key, value) {
     if(strcmp(key,kname) == 0) {
       return(1);
     }
  }
  return(0);
}

int
get_int_from_json(json_object *jobj, char *kname) {
  json_object_object_foreach(jobj,key,value) {
     if(strcmp(key,kname) == 0) {
	return(json_object_get_int(value));
     } else {
	return -1;
     }
  }
}

void
get_string_from_json(json_object *jobj, char *kname, char *str) {
  json_object_object_foreach(jobj, key, value) {
     if(strcmp(key,kname) == 0) {
       strcpy(str, json_object_get_string(value));
     }
  }
}

int
registerConntype(int sock, int type) {
  json_object *jobj;
  jobj = json_object_new_object();
  json_object_object_add(jobj, "CONN_TYPE", json_object_new_int(type));
 
  send_json(sock, jobj);
  json_object_put(jobj);

  return(0);
}

int
setup_ConnectSocket(char *hostname, int port) {
 
  int sock;
  struct sockaddr_in server_addr;
  struct hostent *host;

  if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
  {
    perror("socket");
    return(-1);
  }

  if ((host=gethostbyname(hostname)) == NULL) {  // get the host info
      perror("gethostbyname");
      return(-1);
  }

  server_addr.sin_family = AF_INET;
  server_addr.sin_port = htons(port);
  server_addr.sin_addr = *((struct in_addr *)host->h_addr);
  bzero(&(server_addr.sin_zero),8);

  if (connect(sock, (struct sockaddr *)&server_addr, sizeof(struct sockaddr)) == -1) {
      perror("connect");
      return(-1);
  }

  return(sock);
}

int 
createTable(sqlite3 *db, char *tName) {

  //printf("Table Name - %s\n",tName);

  int rc;
  char *eMsg = 0;
  char *sqlcmd = malloc(MAX_SQL_SIZE);
  strcpy(sqlcmd, "create table if not exists ");
  strcat(sqlcmd, tName);
 
  if( strcmp(tName,SQLITE_DB_TB1NAME) == 0 ) {
	strcat(sqlcmd, " (nodename, timestamp, jsonblob, primary key(nodename))");
  } else if(strcmp(tName,SQLITE_DB_TB2NAME) == 0) {
	strcat(sqlcmd, " (blobid, key, value, primary key(blobid, key))");
  } else {
        printf("createTable : Error - Unsupported table name \n");
        free(sqlcmd);
        return(1);
  }
  //printf("SQL cmd : %s\n",sqlcmd);

  if( (rc = sqlite3_exec(db, sqlcmd, nothing_todo, 0, &eMsg) != SQLITE_OK )) {
        fprintf(stderr, "SQL error: %s\n", eMsg);
        sqlite3_free(eMsg);
  }
  free(sqlcmd);

  return(0);
}
