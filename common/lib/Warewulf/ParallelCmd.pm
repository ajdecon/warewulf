# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::ParallelCmd;

use IO::Select;
use Warewulf::Object;
use Warewulf::ObjectSet;
use Warewulf::Logger;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::ParallelCmd - A parallel command implementation library for Warewulf.

=head1 SYNOPSIS

    use Warewulf::ParallelCmd;

    my $o = Warewulf::ParallelCmd->new();
    $o->fanout(4);
    $o->queue("echo 'long1 start'; sleep 20; echo 'long1 done'");
    for (my $i=1; $i<= 20; $i++) {
        $o->queue("echo '$i start'; sleep 4; echo '$i done'");
    }
    $o->run();

=head1 DESCRIPTION

An object oriented framework to run parallel commands

=head1 METHODS

=over 4

=item new()

The new method is the constructor for this object.  It will create an
object instance and return it to the caller.

=cut

sub
new($$)
{
    my ($proto, @args) = @_;
    my $class = ref($proto) || $proto;
    my $self;

    $self = $class->SUPER::new();
    bless($self, $class);

    return $self;
}

sub
init()
{
    my ($self) = @_;
    my $select = IO::Select->new();
    my $queueset = Warewulf::ObjectSet->new();

    $self->set("select", $select);
    $self->set("queueset", $queueset);

    return($self);
}

=item queue()

Add a command to the queue to run in parallel

=cut

sub
queue($)
{
    my ($self, $command) = @_;
    my $obj = Warewulf::Object->new();
    my $queueset = $self->get("queueset");

    &dprint("Adding command to queue: $command\n");
    $obj->set("command", $command);
    $queueset->add($obj);

    return;
}

=item fanout()

Number of processes to spawn in parallel.

=cut

sub
fanout($$)
{
    my ($self, $fanout) = @_;

    $self->set("fanout", $fanout);

    return;
}


=item wtime()

How many seconds to wait before throwing a warning to the user that a command is
still running. (DEFAULT=15)

=cut

sub
wtime($$)
{
    my ($self, $wtime) = @_;

    $self->set("wtime", $wtime);

    return;
}


=item run()

Run the queued commands

=cut

sub
run($)
{
    my ($self) = @_;
    my $select = $self->get("select");
    my $fanout = $self->get("fanout") || 64;
    my $queueset = $self->get("queueset");
    my $totalcount = $queueset->count() - 1;
    my $queuecount = 0;

    # Spawning the initial fanout within the queue
    for (; $queuecount < $fanout && $queuecount < $totalcount; $queuecount++) {
        $self->forkobj($queueset->get_object($queuecount));
    }

    my $timer = 1;
    while ($select->count() > 0) {
        my $timeleft = $timer+$time - time;
        &dprint("can_read($timeleft) engaged\n");
        my @ready = $select->can_read($timeleft);
        $time = time();
        if (scalar(@ready)) {
            &dprint("got FH activity\n");
            foreach my $fh (@ready) {
                my $buffer;
                my $length;

                do {
                    my $tmp;
                    $length = $fh->sysread($tmp, 1024) || 0;
                    $buffer .= $tmp;
                } while ( $length == 1024 );

                if ($buffer) {
                    foreach my $line (split(/\n/, $buffer)) {
                        print "$line\n";
                    }

                } else {
                    $self->closefh($fh);
                    # Closed one file handle, so now lets queue the next in the array
                    # if it exists.
                    if ($queuecount <= $totalcount) {
                        $self->forkobj($queueset->get_object($queuecount));
                        $queuecount++;
                    }
                }
            }
        } else {
            &dprint("Invoking the timer\n");
            $self->timer();
        }
    }
}


=back

=head1 SEE ALSO

Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

sub
forkobj($)
{
    my ($self, $obj) = @_;
    my $select = $self->get("select");
    my $command = $obj->get("command");
    my $fh;

    &dprint("Spawning command: $command\n");
    open($fh, "$command |");
    $select->add($fh);

    &dprint("Created fileno: ". $fh->fileno() ."\n");

    $obj->set("fileno", $fh->fileno());
    $obj->set("starttime", time());
}

sub
closefh($)
{
    my ($self, $fh) = @_;
    my $queueset = $self->get("queueset");
    my $select = $self->get("select");
    my $fileno = $fh->fileno();

    my $obj = $queueset->find("fileno", $fileno);
    if ($obj) {
        &dprint("closing out fileno: $fileno\n");

        $select->remove($fh);
        $fh->close();
        $obj->set("done", "1");
        $obj->del("fileno");
    } else {
        &wprint("Could not resolve fileno: $fileno\n");
    }
}

sub
timer($)
{
    my ($self) = @_;
    my $queueset = $self->get("queueset");
    my $curtime = time();
    my $wtime = $self->get("wtime") || 15;

    foreach my $obj ($queueset->get_list()) {
        my $warntime = $obj->get("starttime") + $wtime;
        my $fileno = $obj->get("fileno");
        my $command = $obj->get("command");
        my $warning = $obj->get("warning");
        if (! $obj->get("done") and ! $warning and $fileno and $curtime > $warntime) {
            &wprint("Command still in progress ($command)\n");
            $obj->set("warning", 1);
        }
    }
}


1;
