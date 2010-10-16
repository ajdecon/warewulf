
package Warewulf::Daemon;

use Warewulf::Logger;
use Warewulf::Util;
use Exporter;

our @ISA = ('Exporter');

our @EXPORT = qw (
    &daemonize
    &daemon_check
);

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
        lprint(INFO, "Recieved a SIGHUP... nothing to do here");
        return(1);
    };

    $SIG{TERM} = sub {
        kill 'TERM' => keys %slaves;
        $critical_loop = ();
        if (-f "/var/run/$progname.pid") {
            unlink("/var/run/$progname.pid");
        }
        lprint(INFO, "Recieved a SIGTERM... exiting");
    };

    $SIG{INT} = sub {
        kill 'INT' => keys %slaves;
        $critical_loop = ();
        if (-f "/var/run/$progname.pid") {
            unlink("/var/run/$progname.pid");
        }
        lprint(INFO, "Recieved a SIGINIT... exiting");
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
