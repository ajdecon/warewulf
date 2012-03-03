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

