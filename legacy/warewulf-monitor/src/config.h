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

// The Generic Buffersize to use
#define BUFFERSIZE 511

// The Packet Buffersize to use
#define PACKETSIZE 1450

// Where is the status file to determine the node status
#define STATUSFILE "/.nodestatus"

// Port to send UDP status packages to
#define REMOTE_SERVER_PORT 9873

// Location of lock file
#define PIDFILE "/var/lock/subsys/wulfd"

// Location of the distro release files
#define GENERIC_RELEASE "/etc/release"
#define CAOS_RELEASE "/etc/caos-release"
#define REDHAT_RELEASE "/etc/redhat-release"
#define FEDORA_RELEASE "/etc/fedora-release"
#define SUSE_RELEASE "/etc/SuSE-release"
#define DEBIAN_RELEASE "/etc/debian_version"
#define GENTOO_RELEASE "/etc/gentoo-release"
#define MANDRAKE_RELEASE "/etc/mandrake-release"
#define MANDRIVA_RELEASE "/etc/mandriva-release"
