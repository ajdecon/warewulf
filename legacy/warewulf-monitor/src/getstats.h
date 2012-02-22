/*
 * Copyright (c) 2004-2006, Greg M. Kurtzer <gmk@lbl.gov>. All
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
 * Written By Greg Kurtzer <gmk@lbl.gov> originally for the Warewulf
 * Cluster toolkit project (http://warewulf.lbl.gov/) and now for
 * Perceus (http://www.perceus.org/).
 *
 */

int get_cpu_count(void);
int get_procs(void);
float get_uptime(void);
long int get_cpu_clock(void);
char * get_cpu_model(void);
char * get_uname_sysname(void);
char * get_uname_nodename(void);
char * get_uname_release(void);
char * get_uname_version(void);
char * get_uname_machine(void);
int get_cpu_util(void);
int get_mem_total(void);
int get_mem_avail(void);
int get_swap_total(void);
int get_swap_avail(void);
float get_load_avg(void);
int get_net_tx(int refresh);
int get_net_rx(int refresh);
int get_userproc_count(void);
char *get_distro(void);
char * get_node_status(void);
