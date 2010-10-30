# Copyright (c) 2003-2010, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# The GNU GPL Document can be found at:
# http://www.gnu.org/copyleft/gpl.html
#
# $Id$
#

package Warewulf::Daemon;

use Warewulf::Logger;
use Warewulf::Util;
use Exporter;

our @ISA = ('Exporter');

our @EXPORT = ('&daemonize', '&daemon_check');

my $DAEMONIZED;

=head1 NAME

Warewulf::Daemon - Run into the background

=head1 ABOUT

The Warewulf::Daemon class facilitates running processes in the background

=head1 SYNOPSIS

    use Warewulf::Daemon;


=item daemonize()

Throw this application into the background

=cut
sub
daemonize()
{
    my $progname = &progname();

    $DAEMONIZED = 1;

    $SIG{PIPE} = 'IGNORE';

    $SIG{HUP} = sub {
        iprint("Recieved a SIGHUP... nothing to do here");
        return(1);
    };

    $SIG{TERM} = sub {
        kill 'TERM' => keys %slaves;
        $critical_loop = ();
        if (-f "/var/run/$progname.pid") {
            unlink("/var/run/$progname.pid");
        }
        iprint("Recieved a SIGTERM... exiting");
    };

    $SIG{INT} = sub {
        kill 'INT' => keys %slaves;
        $critical_loop = ();
        if (-f "/var/run/$progname.pid") {
            unlink("/var/run/$progname.pid");
        }
        iprint("Recieved a SIGINIT... exiting");
    };

    open(STDIN, "/dev/null");
    open(STDOUT, ">/dev/null");
    open(STDERR, ">/dev/null");
    open(PIDFILE, ">/var/run/$progname.pid");
    print PIDFILE $$;
    close PIDFILE;
    fork and exit;

}

=item daemon_check()

Return true if running as a daemon

=cut
sub
daemon_check()
{
    return($DAEMONIZED);
}





1;
