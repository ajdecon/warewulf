/*
 * Copyright (c) 2001-2003 Gregory M. Kurtzer
 * 
 * Copyright (c) 2003-2011, The Regents of the University of California,
 * through Lawrence Berkeley National Laboratory (subject to receipt of any
 * required approvals from the U.S. Dept. of Energy).  All rights reserved.
 *
 * Contributed by Anthony Salgado & Krishna Muriki
 * Warewulf Monitor (globals.h)
 *
 */

#ifndef _GETSTATS_H
#define _GETSTATS_H  1

#include <json/json.h>

// Yup... function declarations...
char* get_cpu_info(json_object*);
char* get_load_avg(json_object*);
char* get_cpu_util(json_object*);
char* get_mem_stats(json_object*);
char* get_node_status(json_object*);
char* get_net_stats(json_object*);
char* get_sysinfo(json_object*);
char* get_uname(json_object*);

#endif /* _GETSTATS_H */

