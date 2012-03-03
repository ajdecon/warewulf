/*
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
 * Written By Greg Kurtzer <GMKurtzer@lbl.gov> for the Warewulf Cluster
 * toolkit project (http://warewulf-cluster.org/).
 *
 */

#ifndef _UTIL_H
#define _UTIL_H  1

/* Make sure we know about what types we're using */
#include <time.h>
#include <json/json.h>
#include <sqlite3.h>

#include "globals.h"

/* Yup... function declarations... */
void insertLookups(int, json_object*, sqlite3*);
void updateLookups(int, json_object*, sqlite3*);
void fillLookups(int, json_object*, sqlite3*);
void insert_json(char*, time_t, json_object*, sqlite3*);
void update_json(char*, time_t, json_object*, sqlite3*);
void insert_update_json(int, char*, time_t, json_object*, sqlite3*);
int NodeBID_fromDB(char*, sqlite3*);
int NodeTS_fromDB(char*, sqlite3*);
char* recvall(int);
int sendall(int, char*, int);
int send_json(int, json_object*);
void array_list_print(array_list*);
void json_parse_complete(json_object*);
void json_parse(json_object*);
char* chop(char*);
json_object* fast_data_parser(char*, array_list*, int);

static int nothing_todo(void*, int, char**, char**);
static int getint_callback(void*, int, char**, char**);

long get_jiffs(cpu_data*);
/* float get_cpu_util_old(void); */

int key_exists_in_json(json_object*, char*);
int get_int_from_json(json_object*, char*);
void get_string_from_json(json_object*, char*, char*);

/* Connection Functions */
int registerConntype(int, int);
int setup_ConnectSocket(char*, int);

/* SQLite Functions */
int createTable(sqlite3*, char*);

#endif /* _UTIL_H */

