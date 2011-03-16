# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::Daemon;

use Warewulf::Logger;
use Warewulf::Util;
use Exporter;

our @ISA = ('Exporter');

our @EXPORT = ('&daemonize', '&daemonized');

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

=item daemonized()

Return true if running as a daemon. If an argument is defined then it will set
daemonized to return true.

=cut
sub
daemonized()
{
    my $set = shift;

    if ($set) {
        $DAEMONIZED = 1;
    }

    return($DAEMONIZED);
}



=head1 SEE ALSO



=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
