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

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/sysinfo.h>
#include <sys/utsname.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <ctype.h>
#include <utmp.h>
#include <unistd.h>
#include <fcntl.h>
#include <dirent.h>
#include <limits.h>

#include "config.h"

int get_cpu_count(void) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	int cpu_count = 0;

	if (( fd = fopen("/proc/cpuinfo", "r")) == NULL ) {
		printf("could not open /proc/cpuinfo!\n");
		exit(EXIT_FAILURE);
	}
	while(!feof(fd)) {
		fgets(buffer, BUFFERSIZE, fd);
		if (! strncmp( buffer, "processor", 9) ){
/*			printf("found: %s\n", buffer);	*/
			cpu_count++;
		}
	}
	fclose(fd);
	return(cpu_count);
}

long int get_cpu_clock(void) {
	FILE *fd;
	long int cpu_clock;
	char *tmp ;
	char buffer[BUFFERSIZE+1];
	cpu_clock = 0;

	if (( fd = fopen("/proc/cpuinfo", "r")) == NULL ) {
		printf("could not open /proc/cpuinfo!\n");
		exit(EXIT_FAILURE);
	}
	while(!feof(fd)) {
		fgets(buffer, BUFFERSIZE, fd);
		if (! strncmp( buffer, "cpu MHz", 7) ) {
			tmp = strchr( buffer, ':' );
			tmp++;
			while (isspace(*tmp)) tmp++;
//         printf("%ld", cpu_clock + atoll(tmp));
			cpu_clock += atoll(tmp);
//			printf("clock: -%d-\n", cpu_clock);
		}
	}
	fclose(fd);
	return(cpu_clock);
}

char * get_cpu_model(void) {
	FILE *fd;
	char *tmp ;
	char buffer[BUFFERSIZE+1];
	static char cpu_model[255];

	if (( fd = fopen("/proc/cpuinfo", "r")) == NULL ) {
		printf("could not open /proc/cpuinfo!\n");
		exit(EXIT_FAILURE);
	}
	while(!feof(fd)) {
		fgets(buffer, BUFFERSIZE, fd);
		if (! strncmp( buffer, "model name", 10) ) {
			tmp = strchr( buffer, ':' );
			tmp++;
			while (isspace(*tmp)) tmp++;
			strncpy(cpu_model, tmp, 254 );
			cpu_model[strlen(cpu_model) - 1] = '\0';
//			printf("model: %s\n", cpu_model);
		}
	}
	fclose(fd);
	return(cpu_model);
}


float get_load_avg(void) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	char *ptr;
	float ret;

	if (( fd = fopen("/proc/loadavg", "r")) == NULL ) {
		printf("could not open /proc/stat!\n");
		exit(EXIT_FAILURE);
	}
	fgets(buffer, BUFFERSIZE, fd);

	ptr = (char *)strtok(buffer, " ");

	ret = strtod(ptr, NULL);

	fclose(fd);
	return(ret);
}

int get_cpu_util(void) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	int ret;
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

		ret = 0;

	} else {

      result = (int) (((u_ticks - u_ticks_o + n_ticks - n_ticks_o)
                     * 100 ) / t_ticks);
	
		// Set the ticks from this loop to again on next loop
      u_ticks_o = u_ticks;
      n_ticks_o = n_ticks;
      s_ticks_o = s_ticks;
      i_ticks_o = i_ticks;
		
		// In the weird case that we get > 100% cpu utilization
		result = (result > 100) ? 100 : result; 
		
		ret = result;
	}

	fclose(fd);
	return(ret);

}

int get_mem_total(void) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	unsigned long int memtotal;
	char *tmp = 0;
	unsigned long int memt = 0;

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
			memtotal = atoll(tmp);           // Turn char string into int
		}
	}

	fclose(fd);
	memt = memtotal / 1024;
	return(memt);
}

int get_mem_avail(void) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	char *tmp = 0;
	unsigned long int memf = 0, memb = 0, mema = 0, memc = 0;

	if (( fd = fopen("/proc/meminfo", "r")) == NULL ) {
		printf("could not open /proc/meminfo!\n");
		exit(EXIT_FAILURE);
	}

	while(!feof(fd)) {
		fgets(buffer, BUFFERSIZE, fd);
		if ( ! strncmp( buffer, "MemFree:", 8) ){
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
		}

	}
	mema = memf + memb + memc;

	fclose(fd);
	return(mema / 1024);
}

int get_swap_total(void) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	unsigned long int memtotal;
	char *tmp = 0;
	unsigned long int mem = 0;

	if (( fd = fopen("/proc/meminfo", "r")) == NULL ) {
		printf("could not open /proc/meminfo!\n");
		exit(EXIT_FAILURE);
	}

	while(!feof(fd)) {
		fgets(buffer, BUFFERSIZE, fd);
		if (! strncmp( buffer, "SwapTotal:", 9) ){
			tmp = strchr( buffer, ':' ); // Set a pointer to ':' char in buffer
			tmp++;                       // +1 to pointer location
			while (isspace(*tmp)) tmp++; // Increment pointer position til real data
			memtotal = atoll(tmp);           // Turn char string into int
		}
	}

	fclose(fd);
	mem = memtotal / 1024;
	return(mem);
}

int get_swap_avail(void) {
	FILE *fd;
	char buffer[BUFFERSIZE+1];
	unsigned long int memtotal;
	char *tmp = 0;
	unsigned long int mem = 0;

	if (( fd = fopen("/proc/meminfo", "r")) == NULL ) {
		printf("could not open /proc/meminfo!\n");
		exit(EXIT_FAILURE);
	}

	while(!feof(fd)) {
		fgets(buffer, BUFFERSIZE, fd);
		if (! strncmp( buffer, "SwapFree:", 9) ){
			tmp = strchr( buffer, ':' ); // Set a pointer to ':' char in buffer
			tmp++;                       // +1 to pointer location
			while (isspace(*tmp)) tmp++; // Increment pointer position til real data
			memtotal = atoll(tmp);           // Turn char string into int
		}
	}

	fclose(fd);
	mem = memtotal / 1024;
	return(mem);
}

int get_net_tx( int refresh ) {
	FILE *fd;
	char buffer[BUFFERSIZE];
	char *ptr;
	unsigned long long transmit = 0;
	unsigned long long t_transmit = 0;
	static unsigned long long transmit_o = 0;

   /* We can't allow a zero refresh! */
   if ( refresh == 0 ) {
      refresh = 1;
   }
	
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
			
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");
			ptr = (char *)strtok(NULL, ": ");

			transmit += atoll(ptr);

		}
	}

	if ( transmit_o ) {
      // Handle 32 bit counter rollover
      t_transmit = (transmit_o > transmit) ?
	                (UINT_MAX - transmit_o) + transmit :
	                transmit - transmit_o;
	
      t_transmit = (unsigned long)(((t_transmit / refresh) + 512) / 1024);
	}

	transmit_o = transmit;

	fclose(fd);
	return(t_transmit);
}

int get_net_rx( int refresh ) {
	FILE *fd;
	char buffer[BUFFERSIZE];
	char *ptr;
	unsigned long long receive = 0;
	unsigned long long t_receive = 0;
	static unsigned long long receive_o = 0;

   /* We can't allow a zero refresh! */
   if ( refresh == 0 ) {
      refresh = 1;
   }
	
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

		}
	}

	if ( receive_o ) {
      // Handle 32 bit counter rollover
      t_receive = (receive_o > receive) ?
                  (UINT_MAX - receive_o) + receive :
                  receive - receive_o;
	
      t_receive = (unsigned long)(((t_receive / refresh) + 512) / 1024);
	}

	receive_o = receive;

	fclose(fd);
	return(t_receive);
}

int get_procs(void) {
	struct sysinfo sys_info;

	sysinfo(&sys_info);

	return(sys_info.procs);
}

float get_uptime(void) {
	struct sysinfo sys_info;

	sysinfo(&sys_info);

	return(sys_info.uptime / 86400.0);
}

char * get_uname_sysname(void) {
	struct utsname unameinfo;
	static char ret[BUFFERSIZE+1];

	uname(&unameinfo);

	snprintf(ret, BUFFERSIZE, "%s", unameinfo.sysname);

	return(ret);
}

char * get_uname_nodename(void) {
	struct utsname unameinfo;
	static char ret[BUFFERSIZE+1];

	uname(&unameinfo);

	snprintf(ret, BUFFERSIZE, "%s", unameinfo.nodename);

	return(ret);
}

char * get_uname_release(void) {
	struct utsname unameinfo;
	static char ret[BUFFERSIZE+1];

	uname(&unameinfo);

	snprintf(ret, BUFFERSIZE, "%s", unameinfo.release);

	return(ret);
}

char * get_uname_version(void) {
	struct utsname unameinfo;
	static char ret[BUFFERSIZE+1];

	uname(&unameinfo);

	snprintf(ret, BUFFERSIZE, "%s", unameinfo.version);

	return(ret);
}

char * get_uname_machine(void) {
	struct utsname unameinfo;
	static char ret[BUFFERSIZE+1];

	uname(&unameinfo);

	snprintf(ret, BUFFERSIZE, "%s", unameinfo.machine);

	return(ret);
}

int get_userproc_count(void) {
   int user_count=0;
   DIR *od;
   struct dirent *rd;
   char buff[BUFFERSIZE+1];
   struct stat statbuf;

   od=opendir("/proc/");
   if (!od)
      return 0; // error


   rd=readdir(od);
   while(rd) {
      snprintf(buff, BUFFERSIZE, "/proc/%s/cmdline", rd->d_name);
      if (stat(buff, &statbuf) != -1 ) {
         if ( statbuf.st_uid >= 500 ) {
         user_count++;
//         printf("userid: %d\n", namelist[i]->d_name);
         }
      }
      rd=readdir(od); // read next entry
   }
   closedir(od);
   return(user_count);
}

char *get_distro(void) {
   FILE *fd;
	static char ret[BUFFERSIZE];
	unsigned int tmp = 0;

   fd = fopen(GENERIC_RELEASE, "r");
   if ( fd == NULL ) {
      fd = fopen(CAOS_RELEASE, "r");
   }
   if ( fd == NULL ) {
      fd = fopen(REDHAT_RELEASE, "r");
   }
   if ( fd == NULL ) {
      fd = fopen(FEDORA_RELEASE, "r");
   }
   if ( fd == NULL ) {
      fd = fopen(SUSE_RELEASE, "r");
   }
   if ( fd == NULL ) {
      fd = fopen(DEBIAN_RELEASE, "r");
   }
   if ( fd == NULL ) {
      fd = fopen(GENTOO_RELEASE, "r");
   }
   if ( fd == NULL ) {
      fd = fopen(MANDRAKE_RELEASE, "r");
   }
   if ( fd == NULL ) {
      fd = fopen(MANDRIVA_RELEASE, "r");
   }

   if ( fd != NULL ) {
      fgets(ret, BUFFERSIZE-1, fd);
      fclose(fd);
      tmp = strlen(ret) - 1;
      ret[tmp] = '\0';
   }

   return(ret);
}


char * get_node_status(void) {
   FILE *fd;
   unsigned int tmp = 0;
   char buffer[BUFFERSIZE];
   static char ret[BUFFERSIZE];

   if((fd = fopen(STATUSFILE, "r")) != NULL) {

      fgets(buffer, BUFFERSIZE-1, fd);
      fclose(fd);

      while (!isspace(buffer[tmp])) tmp++;
      buffer[tmp] = '\0';

      snprintf(ret, strlen(buffer)+13, "%s", buffer);

   }

   return(ret);
}
