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

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <limits.h>
#include <sys/socket.h>
#include <sys/sysinfo.h>
#include <sys/utsname.h>
#include <ctype.h>

// The Generic Buffersize to use
#define BUFFERSIZE 511

// Where is the status file to determin the node status
#define STATUSFILE "/.nodestatus"

// Sleep time inbetween loops
#define REFRESH 1

char * get_cpu_info(json_object *jobj) {
	FILE *fd;
	unsigned int cpu_count = 0;
	unsigned int cpu_clock = 0;
	char *tmp ;
	char buffer[BUFFERSIZE+1];
	char cpu_model[BUFFERSIZE+1];
	static char ret[BUFFERSIZE+1];

	if (( fd = fopen("/proc/cpuinfo", "r")) == NULL ) {
		printf("could not open /proc/cpuinfo!\n");
		exit(EXIT_FAILURE);
	}
	while(!feof(fd)) {
		fgets(buffer, BUFFERSIZE, fd);
		if (! strncmp( buffer, "processor", 9) ){
//			printf("found: %s\n", buffer);
			cpu_count++;
		}
		if (! strncmp( buffer, "cpu MHz", 7) ) {
			tmp = strchr( buffer, ':' );
			tmp++;
			while (isspace(*tmp)) tmp++;
			cpu_clock += atoll(tmp);
//			printf("clock: -%d-\n", cpu_clock);
		}
		if (! strncmp( buffer, "model name", 10) ) {
			tmp = strchr( buffer, ':' );
			tmp++;
			while (isspace(*tmp)) tmp++;
			strcpy(cpu_model, tmp );
			cpu_model[strlen(cpu_model) - 1] = '\0';
//			cpu_model = *tmp;
//			printf("model: %s\n", cpu_model);
		}
	}
//	printf("CPUCOUNT=%d\nCPUCLOCK=%d\n", cpu_count, cpu_clock);
	snprintf(ret, BUFFERSIZE, "CPUCOUNT=%d\nCPUCLOCK=%d\nCPUMODEL=%s\n", 
		cpu_count, cpu_clock, cpu_model);

        json_object_object_add(jobj,"CPUCOUNT",json_object_new_int(cpu_count));
        json_object_object_add(jobj,"CPUCLOCK",json_object_new_int(cpu_clock));
        json_object_object_add(jobj,"CPUMODEL",json_object_new_string(cpu_model));

	ret[BUFFERSIZE] = '\0';
	fclose(fd);
	return(ret);
}
char * get_load_avg(json_object *jobj) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	static char ret[BUFFERSIZE+1];
	char *ptr;

	if (( fd = fopen("/proc/loadavg", "r")) == NULL ) {
		printf("could not open /proc/stat!\n");
		exit(EXIT_FAILURE);
	}
	fgets(buffer, BUFFERSIZE, fd);

	ptr = (char *)strtok(buffer, " ");

	snprintf(ret, BUFFERSIZE, "LOADAVG=%s\n", 
		ptr);

        json_object_object_add(jobj,"LOADAVG",json_object_new_string(ptr));

	fclose(fd);
	ret[BUFFERSIZE] = '\0';
	return(ret);
}

char * get_cpu_util(json_object *jobj) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	static char ret[BUFFERSIZE+1];
	char *tmp;
	unsigned long int u_ticks = 0, n_ticks = 0, s_ticks = 0, 
		i_ticks = 0, t_ticks = 0;
        static unsigned long int u_ticks_o = 0, n_ticks_o = 0,
                s_ticks_o = 0, i_ticks_o = 0;
	unsigned int result;

	if (( fd = fopen("/proc/stat", "r")) == NULL ) {
		printf("could not open /proc/stat!\n");
		exit(EXIT_FAILURE);
	}

	while(!feof(fd)) {
		fgets(buffer, BUFFERSIZE, fd);
		if (! strncmp( buffer, "cpu ", 4) ){
//			printf("found: %s\n", buffer);

			// skip 'cpu'
			tmp = (char *)strtok(buffer, " ");

			// user
			tmp = (char *)strtok(NULL, " ");
			u_ticks = atoll(tmp);

			// nice
			tmp = (char *)strtok(NULL, " ");
			n_ticks = atoll(tmp);

			// system
			tmp = (char *)strtok(NULL, " ");
			s_ticks = atoll(tmp);

			// idle
			tmp = (char *)strtok(NULL, " ");
			i_ticks = atoll(tmp);

			break;
		}
	}

        t_ticks = ((u_ticks + s_ticks + i_ticks + n_ticks) -
                  (u_ticks_o + s_ticks_o + i_ticks_o + n_ticks_o) );

	if ( t_ticks == 0 ) {

		/* 
		 * Don't do any calcs because they would fail, 
		 * and set the return values 
		*/

		snprintf(ret, BUFFERSIZE, "CPUUTIL=0\n");

        json_object_object_add(jobj,"CPUUTIL",json_object_new_int(result));

		ret[BUFFERSIZE] = '\0';

	} else {

	        result = (int) (((u_ticks - u_ticks_o + n_ticks - n_ticks_o) * 100 ) / t_ticks);
	
		// Set the ticks from this loop to again on next loop
	        u_ticks_o = u_ticks;
	        n_ticks_o = n_ticks;
	        s_ticks_o = s_ticks;
	        i_ticks_o = i_ticks;
		
		// In the weird case that we get > 100% cpu utilization
		result = (result > 100) ? 100 : result; 
		
		snprintf(ret, BUFFERSIZE, "CPUUTIL=%d\n",
			 result);

        json_object_object_add(jobj,"CPUUTIL",json_object_new_int(result));

		ret[BUFFERSIZE] = '\0';
	}

	fclose(fd);
	return(ret);

}

char * get_mem_stats(json_object *jobj) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	static char ret[BUFFERSIZE+1];
	char *tmp = 0;
	unsigned long int memt = 0, memf = 0, memb = 0, mema = 0, memc = 0,
		swapt = 0, swapf = 0;
	float memp = 0.00, swapp = 0.00;

	if (( fd = fopen("/proc/meminfo", "r")) == NULL ) {
		printf("could not open /proc/meminfo!\n");
		exit(EXIT_FAILURE);
	}

	while(!feof(fd)) {
		fgets(buffer, BUFFERSIZE, fd);
		if (! strncmp( buffer, "MemTotal:", 9) ){
			tmp = strchr( buffer, ':' ); // Set a pointer to ':' char in buffer
			tmp++;                       // +1 to pointer location
			while (isspace(*tmp)) tmp++; // Increment pointer position til real data
			memt = atoll(tmp);           // Turn char string into int
		} else if ( ! strncmp( buffer, "MemFree:", 8) ){
			tmp = strchr( buffer, ':' );
			tmp++;
			while (isspace(*tmp)) tmp++;
			memf = atoll(tmp);
		} else if ( ! strncmp( buffer, "Buffers:", 8) ){
			tmp = strchr( buffer, ':' );
			tmp++;
			while (isspace(*tmp)) tmp++;
			memb = atoll(tmp);
		} else if ( ! strncmp( buffer, "Cached:", 7) ){
			tmp = strchr( buffer, ':' );
			tmp++;
			while (isspace(*tmp)) tmp++;
			memc = atoll(tmp);
		} else if ( ! strncmp( buffer, "SwapTotal:", 10) ){
			tmp = strchr( buffer, ':' );
			tmp++;
			swapt = atoll(tmp);
		} else if ( ! strncmp( buffer, "SwapFree:", 9) ){
			tmp = strchr( buffer, ':' );
			tmp++;
			swapf = atoll(tmp);
		}

	}
	mema = memf + memb + memc;
//	printf("MEMTOTAL=%lu\nMEMAVAIL=%lu\n", 
//		memt, memf + memb + memc );
	if ( memt > '0' ) {
		memp = ( ( ( 1.0 * memt ) - ( 1.0 * mema ) ) / ( 1.0 * memt ) ) * 100;
	}
	if ( swapt > '0' ) {
		swapp = ( ( ( 1.0 * swapt ) - ( 1.0 * swapf ) ) / ( 1.0 * swapt ) ) * 100;
	}
	snprintf(ret, BUFFERSIZE, 
		"MEMTOTAL=%lu\nMEMAVAIL=%lu\nMEMUSED=%lu\nMEMPERCENT=%.0f\n"
		"SWAPTOTAL=%lu\nSWAPFREE=%lu\nSWAPUSED=%lu\nSWAPPERCENT=%.0f\n", 
		memt / 1024,
		mema / 1024,
		( memt - mema ) / 1024,
		memp,
		swapt / 1024,
		swapf / 1024,
		( swapt - swapf ) / 1024,
		swapp);
	ret[BUFFERSIZE] = '\0';

        json_object_object_add(jobj,"MEMTOTAL",json_object_new_int(memt/1024));
        json_object_object_add(jobj,"MEMAVAIL",json_object_new_int(mema/1024));
        json_object_object_add(jobj,"MEMUSED",json_object_new_int((memt - mema)/1024));
        json_object_object_add(jobj,"MEMPERCENT",json_object_new_int(memp));
        json_object_object_add(jobj,"SWAPTOTAL",json_object_new_int(swapt/1024));
        json_object_object_add(jobj,"SWAPFREE",json_object_new_int(swapf/1024));
        json_object_object_add(jobj,"SWAPUSED",json_object_new_int((swapt - swapf)/1024));
        json_object_object_add(jobj,"SWAPPERCENT",json_object_new_int(swapp));

	fclose(fd);
	return(ret);
}

char * get_node_status(json_object *jobj) {
	FILE *fd;
	unsigned int tmp = 0;
	char buffer[BUFFERSIZE];
	static char ret[BUFFERSIZE];

	strncpy(buffer, "unavailable\0", 12);

	if((fd = fopen(STATUSFILE, "r")) != NULL) {
		fgets(buffer, BUFFERSIZE-1, fd);
		fclose(fd);
	}

	while (!isspace(buffer[tmp])) tmp++;
	buffer[tmp] = '\0';

	snprintf(ret, strlen(buffer)+13, "NODESTATUS=%s\n",
		buffer);

        json_object_object_add(jobj,"NODESTATUS",json_object_new_string(buffer));

        return(ret);
}

char * get_net_stats(json_object *jobj) {
	FILE *fd;
	char buffer[BUFFERSIZE];
	static char ret[BUFFERSIZE+1];
	char *ptr;
	unsigned long long receive = 0, transmit = 0;
	unsigned long long t_receive = 0, t_transmit = 0;
	static unsigned long long receive_o = 0, transmit_o = 0;

	
	if ((fd = fopen("/proc/net/dev", "r")) == NULL) {
		printf("could not open /proc/net/dev!\n");
		exit(EXIT_FAILURE);
	}
	
        // skip first two lines
        fgets(buffer, BUFFERSIZE-1, fd);
        fgets(buffer, BUFFERSIZE-1, fd);

        while(!feof(fd)) {
                fgets(buffer, BUFFERSIZE-1, fd);

                ptr = (char *)strtok(buffer, ": ");

		if ( strncmp("lo", ptr, 2 ) || strncmp("sit0", ptr, 4 ) ) {

			ptr = (char *)strtok(NULL, ": ");
			if(ptr == NULL)
				break;
			
			receive += atoll(ptr);

			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");

			transmit += atoll(ptr);

//			printf("-> %s, %llu:%llu, %llu:%llu\n", buffer, receive, receive_o, transmit, transmit_o);

		}

	}

	if ( receive_o ) {
	        // Handle 32 bit counter rollover
	        t_receive = (receive_o > receive) ?
	                (UINT_MAX - receive_o) + receive :
	                receive - receive_o;
	
	        t_receive = (unsigned long)(((t_receive / REFRESH) + 512) / 1024);
	}
	if ( transmit_o ) {
	        // Handle 32 bit counter rollover
	        t_transmit = (transmit_o > transmit) ?
	                (UINT_MAX - transmit_o) + transmit :
	                transmit - transmit_o;
	
	        t_transmit = (unsigned long)(((t_transmit / REFRESH) + 512) / 1024);
	}
/*

	if ( receive_o ) {
		t_receive = (unsigned long)
			((((receive - receive_o) / REFRESH) + 512) / 1024) - 1;
	}
	if ( transmit_o ) {
		t_transmit = (unsigned long)
			((((transmit - transmit_o)/ REFRESH) + 512) / 1024) - 1;
	}
*/
	receive_o = receive;
	transmit_o = transmit;

	snprintf(ret, BUFFERSIZE, "NETTRANSMIT=%llu\nNETRECIEVE=%llu\n",
		t_transmit,
		t_receive);

        json_object_object_add(jobj,"NETTRANSMIT",json_object_new_int(t_transmit));
        json_object_object_add(jobj,"NETRECEIVE",json_object_new_int(t_receive));

	ret[BUFFERSIZE] = '\0';

	fclose(fd);
	return(ret);
}

char * get_sysinfo(json_object *jobj) {
	struct sysinfo sys_info;
	static char ret[BUFFERSIZE+1];

	// TODO: Insert your favorite error checking scheme here!
	sysinfo(&sys_info);

	snprintf(ret, BUFFERSIZE, "PROCS=%d\nUPTIME=%lu\n",
		sys_info.procs,
		sys_info.uptime);
	ret[BUFFERSIZE] = '\0';

        json_object_object_add(jobj,"PROCS",json_object_new_int(sys_info.procs));
        json_object_object_add(jobj,"UPTIME",json_object_new_int(sys_info.uptime));

	return(ret);
}

char * get_uname(json_object *jobj) {
	struct utsname unameinfo;
	static char ret[BUFFERSIZE+1];

	// TODO: Insert your favorite error checking scheme here!
	uname(&unameinfo);

	snprintf(ret, BUFFERSIZE, "SYSNAME=%s\nNODENAME=%s\nRELEASE=%s\nVERSION=%s\nMACHINE=%s\n",
		unameinfo.sysname,
		unameinfo.nodename,
		unameinfo.release,
		unameinfo.version,
		unameinfo.machine);

        json_object_object_add(jobj,"SYSNAME",json_object_new_string(unameinfo.sysname));
        json_object_object_add(jobj,"NODENAME",json_object_new_string(unameinfo.nodename));
        json_object_object_add(jobj,"RELEASE",json_object_new_string(unameinfo.release));
        json_object_object_add(jobj,"VERSION",json_object_new_string(unameinfo.version));
        json_object_object_add(jobj,"MACHINE",json_object_new_string(unameinfo.machine));

	ret[BUFFERSIZE] = '\0';

	return(ret);
}
