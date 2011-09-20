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

#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<ctype.h>
#include<json/json.h>
#include<sqlite3.h>
#include "globals.h"

// Forward declarations
int sendall(int s, char *buf, int total);

char *
recvall(int sock)
{
  int bytes_read, bytes_left;

  char *rbuf = malloc(MAXPKTSIZE);

  apphdr *app_h = (apphdr *) rbuf;
  appdata *app_d = (appdata *) (rbuf + sizeof(apphdr));

  //block to receive the whole header
  if ((bytes_read=recv(sock, rbuf, sizeof(apphdr), MSG_WAITALL)) == -1) {
    perror("recv");
    exit(1);
  }
  //printf("app_h->len: %d\n", app_h->len);
  //printf("Received - %s\n",app_d->payload);

  char *buffer;
  // plus 1 to store the NULL char
  buffer = (char *) malloc (app_h->len+1);
  buffer[0] = '\0';

  bytes_left = app_h->len;
  bytes_read = bytes_read - sizeof(apphdr);

  int count;
  while(bytes_read < bytes_left){
    if((count = recv(sock, rbuf, MAXPKTSIZE-1,0)) == -1){
      perror("recv");
      exit(1);
    }
    rbuf[count] = '\0';
    strcat(buffer, rbuf);
    bytes_read += count;
  }
  free(rbuf);
  buffer[bytes_left] = '\0';
  return buffer;
}

int
send_json(int sock, json_object *jobj)
{

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

static
int
callback(void *NotUsed, int argc, char **argv, char **azColName)
{
  int i;
  for(i=1; i<argc; i++){
    printf("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
  }
  printf("\n");
  return 0;
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


void 
update_db(json_object *jobj, sqlite3 *db)
{
  char *sqlite_cmd = malloc(sizeof(char)*1024);
  strcpy(sqlite_cmd, "INSERT OR REPLACE INTO WWSTATS(");
  char *values = malloc(sizeof(char)*1024);
  strcpy(values, " VALUES('");
  int rc;

  json_object_object_foreach(jobj, key, value){
    strcat(sqlite_cmd, key);
    strcat(sqlite_cmd,",");
    strcat(values, json_object_get_string(value));
    strcat(values, "','");
  }
  sqlite_cmd[strlen(sqlite_cmd)-1] = ')';
  
  strcat(sqlite_cmd, values);
  
  sqlite_cmd[strlen(sqlite_cmd)-2] = ')';
  sqlite_cmd[strlen(sqlite_cmd)-1] = '\0';
  printf("Command was: %s\n", sqlite_cmd);

  rc = sqlite3_exec(db, sqlite_cmd,callback, 0, 0); 

  if( rc!=SQLITE_OK ){
    fprintf(stderr, "SQL error: %s\n", 0);
    sqlite3_free(0);
  }

  free(sqlite_cmd);
  free(values);
}

void json_parse_complete(json_object *jobj);

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

// These declarations should go into globals.h --kmuriki
struct cpu_data{
  long tj;
  long wj;
};

static int
json_from_db2(void *void_json, int argc, char **argv, char **azColName)
{
  int i;
  json_object *json_db = (json_object *) void_json;
  json_object *tmp = json_object_new_object();
  char *key_buf = malloc(sizeof(char)*1024);
  for(i = 0; i < argc; i++){
    json_object_object_add(tmp, azColName[i], json_object_new_string(argv[i]));
  }  
// printf("argv[0] = %s\n", argv[0]);
// printf("argv[1] = %s\n", argv[1]);
  json_object_object_add(json_db, argv[0], tmp); // REQUIRE ROWID IS FIRST ARG
  free(key_buf);
  return 0;
}

static int
json_from_db(void *void_json, int argc, char **argv, char **azColName)
{
  int i;
  json_object *json_db = (json_object *) void_json;
  json_object *tmp = json_object_new_object();
  printf("\nargv[0] = %s\n", argv[0]);
  for(i = 0; i < argc; i++){
    json_object_object_add(tmp, azColName[i], (json_object *) json_object_new_string(argv[i]));
  }
  json_object_object_add(json_db, argv[0], tmp);
  return 0;
}

long
get_jiffs(struct cpu_data *cd)
{
  long total_jiffs, work_jiffs;
  int iters, i;
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

void
update_db2(json_object *jobj, sqlite3 *db)
{
  
  int rc;
  printf("Starting foreach loop...\n");
 
  json_object_object_foreach(jobj, key, value){
    char *sqlite_cmd = malloc(sizeof(char)*1024);
    strcpy(sqlite_cmd, "INSERT OR REPLACE INTO WWSTATS(NodeName, key, value) ");
    char *values = malloc(sizeof(char)*1024);
    strcpy(values, " VALUES('");
    json_object *tmp = value;
    json_object *jstring = json_object_object_get(tmp, "NodeName");
    json_parse_complete(tmp);
    strcat(values, json_object_get_string(jstring));
    strcat(values, "' , '");
    
    jstring = json_object_object_get(tmp, "key");
    strcat(values, json_object_get_string(jstring));
    strcat(values, "' , '");
    
    jstring = json_object_object_get(tmp, "value");
    strcat(values, json_object_get_string(jstring));
    strcat(values, "' )");
    
    strcat(sqlite_cmd, values);
    printf("Command was: %s\n", sqlite_cmd);

    rc = sqlite3_exec(db, sqlite_cmd,callback, 0, 0); 
    printf("Done update\n");
    if( rc!=SQLITE_OK ){
      fprintf(stderr, "SQL error: %s\n", 0);
      sqlite3_free(0);
    }
    
    free(sqlite_cmd);
    free(values);
  }
  printf("Exiting update_db2\n");
}
