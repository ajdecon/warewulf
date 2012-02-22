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


#include <unistd.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <syslog.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "getstats.h"
#include "send.h"
#include "config.h"


// We will stay in daemon mode while this is set
int do_loop = '1';
int exitcode = '0';
unsigned int debug = 0;
char **global_argv;

static void
signal_handler(int i)
{
    switch (i) {
        case SIGILL:
        case SIGABRT:
        case SIGFPE:
        case SIGSEGV:
        case SIGPIPE:
        case SIGUSR1:
        case SIGUSR2:
        case SIGBUS:
            syslog(LOG_ERR, "Fatal signal %d received.  Attempting restart.", i);
            execvp(global_argv[0], global_argv);
            syslog(LOG_ERR, "Restart failed -- %s", strerror(errno));
            /* DROP */
        case SIGTERM:
            if (debug) {
                printf("SIGTERM recieved, ending loop\n");
            }
            do_loop = 0;
            exitcode = 254;
            break;
        case SIGINT:
            if (debug) {
                printf("SIGINT recieved, ending loop\n");
            }
            do_loop = 0;
            exitcode = 254;
            break;
        default:
            if (debug) {
                printf("SIG* recieved... What's that for?\n");
            }
            exitcode = 255;
            break;
    }
}

static void usage(char *program) {
        printf("usage: %s [options]\n"
               "\n"
               "[options]\n"
               "   -m <hostname>       hostname of the warewulf master [def=localhost]\n"
               "   -r <refresh>        Refresh interval in seconds [def=1]\n"
               "   -t <threshhold>     Threshhold (percent) for status changes [def=.05]\n"
               "   -u <update>         Seconds to force an update if threshhold hasn't been reached [def=45]\n"
               "   -d                  debug and no fork()\n"
               "   -h                  this help\n"
               "\nWulfd is written and maintained by Greg Kurtzer <gmk@lbl.gov>\n",
               program);
        exit(exitcode);
}


int main (int argc, char **argv) {
   FILE *fd;
   char packet[PACKETSIZE+1];
   signed char c;
   pid_t pid, oldpid, sid;
        char buffer[BUFFERSIZE+1];
        char hostname[255];
   int refresh ;
   float thresh;
   int update;
   time_t epoch, last;
   int cpu_count, procs, _procs, cpu_util, _cpu_util, mem_total, mem_avail,
      _mem_avail, swap_total, swap_avail, _swap_avail, net_rx, _net_rx,
      net_tx, _net_tx, count, user_proc, _user_proc;
   long cpu_clock;
   char uname_sysname[BUFFERSIZE-1], uname_nodename[BUFFERSIZE-1],
      uname_release[BUFFERSIZE-1], uname_version[BUFFERSIZE-1],
      uname_machine[BUFFERSIZE-1], cpu_model[BUFFERSIZE+1],
      distro[BUFFERSIZE+1], node_status[BUFFERSIZE-1],
      _node_status[BUFFERSIZE-1];
   double uptime, _uptime;
   float load_avg, _load_avg;
   int send_packet = 1;

   /* Save parameters for later. */
   global_argv = argv;

   /* Default Options */
   last = 0;
   refresh = 1;
   update = 45;
   thresh = .05;

   /* Starting Points */
   _procs = 0;
   _uptime = 0;
   _cpu_util = 0;
   _mem_avail = 0;
   _swap_avail = 0;
   _load_avg = 0;
   _net_rx = 0;
   _net_tx = 0;
   count = 0;


   /* Catch some typical signals when thrown this way */
   signal(SIGTERM, signal_handler);
   signal(SIGINT, signal_handler);
   signal(SIGHUP, signal_handler);

   strcpy(hostname, "localhost");

   /* Open syslog right away. */
   openlog("wulfd", LOG_NDELAY | LOG_PID, LOG_DAEMON);

   while ((c = getopt (argc, argv, "m:r:t:u:dh")) != EOF) {
       switch (c) {
           case 'm':
               strcpy(hostname, optarg);
               break;
           case 'r':
               refresh = atol(optarg);
               break;
           case 't':
               thresh = strtod(optarg, NULL);
               break;
           case 'u':
               update = atol(optarg);
               break;
           case 'd':
               debug++;
               break;
           default:
               usage(argv[0]);
               break;
       }
   }

   if ((fd = fopen(PIDFILE, "r")) != NULL) {
      fgets(buffer, BUFFERSIZE, fd);
      oldpid = atoi(buffer);
      fprintf(stderr, "Wulf daemon already running; %s, PID: %d\n", PIDFILE, oldpid);
      fclose(fd);
      exit(1);
   }


   /*
    * Send a test packet with nothing in it to make sure we
    * resolve properly.
    */
   udp_send(hostname, "");

   if ( ! debug ) {

      if ( (pid = fork() ) < 0 ) {
         exit(exitcode);
      }
      if(pid != 0) {
         exit(0);
      }
      umask(0);
      sid = setsid();
      if (sid < 0)
          exit(exitcode);

      if ((chdir("/")) < 0)
          exit(exitcode);

      close(STDIN_FILENO);
      open("/dev/null", O_RDWR);      
      close(STDOUT_FILENO);
      open("/dev/null", O_RDWR);
      close(STDERR_FILENO);
      open("/dev/null", O_RDWR);
      
      if ((fd = fopen(PIDFILE, "w")) == NULL) {
         fprintf(stderr, "Couldn't write lock file %s!...\ncontinuing anyway...\n", PIDFILE);
      } else {
         pid = getpid();
         fprintf(fd, "%d\n", pid);
         fflush(fd);
         fclose(fd);
      }
   } else {
      printf("Starting debug mode...\n");
      printf("Refresh: %i\n", refresh);
      printf("Threshhold: %f\n", thresh);
      printf("Force update: %i\n", update);
   }

   /*
    * cpu_info shouldnt change while daemon is running, so we should
    * just read it in once
    */
   cpu_count= get_cpu_count();
   cpu_clock = get_cpu_clock();
   strcpy(cpu_model, get_cpu_model());
   strcpy(uname_sysname, get_uname_sysname());
   strcpy(uname_nodename, get_uname_nodename());
   strcpy(uname_release, get_uname_release());
   strcpy(uname_version, get_uname_version());
   strcpy(uname_machine, get_uname_machine());
   strcpy(distro, get_distro());
   mem_total = get_mem_total();
   swap_total = get_swap_total();

   // If we have gotten this far, we may as well fork and exit (soon)
   while (do_loop) {
      // Assembly of the packet
      epoch = time(NULL);
      procs = get_procs();
      uptime = get_uptime();
      cpu_util = get_cpu_util();
      mem_avail = get_mem_avail();
      swap_avail = get_swap_avail();
      load_avg = get_load_avg();
      net_rx = get_net_rx(refresh);
      net_tx = get_net_tx(refresh);
      user_proc = get_userproc_count();
      strcpy(node_status, get_node_status());

      if ( epoch - last > update || last == 0 ) {
         send_packet = 1;
      } else {
         send_packet = 0;
      }

      if ( _procs != procs )
         send_packet = 1;

   /* The last + 2 is a fuzz factor so it doesn't send on every cpu
    * click near the bottom (eg. 0->1->2, etc...).
    */
      if ( abs(_cpu_util - cpu_util) > (cpu_util * thresh + 2))
         send_packet = 1;

      if ( abs(_mem_avail - mem_avail) > (mem_avail * thresh + 2))
         send_packet = 1;

      if ( abs(_swap_avail - swap_avail) > (swap_avail * thresh + 2))
         send_packet = 1;

      if ( abs(_load_avg - load_avg) > (load_avg * thresh + 2))
         send_packet = 1;

      if ( abs(_net_tx - net_tx) > (net_tx * thresh + 2))
         send_packet = 1;

      if ( abs(_net_rx - net_rx) > (net_rx * thresh + 2))
         send_packet = 1;

      if ( _user_proc != user_proc )
         send_packet = 1;

      if ( strcmp(node_status, _node_status))
         send_packet = 1;

      if ( send_packet == 1 ) {
/*
         snprintf(packet, PACKETSIZE, "NODE-1.0=%s&%s&%ld&%d&%s&%d&%s&%.2f&%s&%d&%d&%d&%d&%d&%d&%d&%s&%.2f&%d&%s\n",
                  uname_nodename, uname_machine, cpu_clock, cpu_count,
                  cpu_model, cpu_util, distro, load_avg, uname_release, mem_total,
                  mem_total - mem_avail, net_rx, net_tx, procs,
                  swap_total, swap_total - swap_avail, uname_sysname,
                  uptime, user_proc, uname_version);

*/

         snprintf(packet, PACKETSIZE,
            "CPUCOUNT=%d\n"
            "CPUCLOCK=%ld\n"
            "CPUMODEL=%s\n"
            "PROCS=%d\n"
            "UPTIME=%.2f\n"
            "DISTRO=%s\n"
            "SYSNAME=%s\n"
            "NODENAME=%s\n"
            "RELEASE=%s\n"
            "VERSION=%s\n"
            "MACHINE=%s\n"
            "CPUUTIL=%d\n"
            "MEMTOTAL=%d\n"
            "MEMUSED=%d\n"
            "SWAPTOTAL=%d\n"
            "SWAPUSED=%d\n"
            "LOADAVG=%.2f\n"
            "NETRECIEVE=%d\n"
            "NETTRANSMIT=%d\n"
            "USERPROC=%d\n"
            "NODESTATUS=%s\n",
            cpu_count,
            cpu_clock,
            cpu_model,
            procs,
            uptime,
            distro,
            uname_sysname,
            uname_nodename,
            uname_release,
            uname_version,
            uname_machine,
            cpu_util,
            mem_total,
            mem_total - mem_avail,
            swap_total,
            swap_total - swap_avail,
            load_avg,
            net_rx,
            net_tx,
            user_proc,
            node_status);
         if ( debug )
            printf("<packet count=%i sendto=%s>\n%s</packet>\n", count, hostname, packet);
         // Send the packet!
         udp_send(hostname, packet);
         last = epoch;
         _procs = procs;
         _cpu_util = cpu_util;
         _mem_avail = mem_avail;
         _swap_avail = swap_avail;
         _load_avg = load_avg;
         _net_rx = net_rx;
         _net_tx = net_tx;
         _user_proc = user_proc;
         strcpy(_node_status, node_status);

      }
      sleep(refresh);
      count++;
   }
   snprintf(packet, PACKETSIZE,
      "CPUUTIL=0\n"
      "CPUCLOCK=0\n"
      "MACHINE=n/a\n"
      "UPTIME=n/a\n"
      "PROCS=0\n"
      "USERPROC=99\n"
      "LOADAVG=0\n"
      "NODENAME=%s\n"
      "NODESTATUS=SHUTDOWN\n",
      uname_nodename);
   udp_send(hostname, packet);
   unlink(PIDFILE);
   if ( debug ) {
      printf("wulfd exiting: %i\n", exitcode);
   }
   syslog(LOG_ERR, "Terminating with exit code %d", exitcode);
   closelog();
   return(exitcode);
}
