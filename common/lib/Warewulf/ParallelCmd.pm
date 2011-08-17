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
    $o->wtime(8);
    $o->ktime(10);
    $o->queue("ping -c 20 www.yahoo.com");
    for (my $i=1; $i<= 4; $i++) {
        $o->queue("sleep 5");
    }
    $o->queue("ping -c 20 www.google.com");
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
    $self->set("fanout", 64);

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

    if ($fanout and $fanout =~ /^([0-9]+)$/) {
        $self->set("fanout", $1);
    }

    return $self->get("fanout");
}


=item wtime()

How many seconds to wait before throwing a warning to the user that a command is
still running. If undefined, no warning will be given.

=cut

sub
wtime($$)
{
    my ($self, $wtime) = @_;

    if ($wtime and $wtime =~ /^([0-9]+)$/) {
        $self->set("wtime", $1);
    }

    return $self->get("wtime");
}


=item ktime()

How many seconds to wait before killing the processes. If undefined, the
process will wait indefinitely.

=cut

sub
ktime($$)
{
    my ($self, $ktime) = @_;

    if ($ktime and $ktime =~ /^([0-9]+)$/) {
        $self->set("ktime", $1);
    }

    return $self->get("ktime");
}


=item pcount()

How many processes are running

=cut

sub
pcount($$)
{
    my ($self, $increment) = @_;

    if ($increment and $increment =~ /^\+([0-9]+)$/) {
        $self->set("pcount", $self->get("pcount") + $1);
    } elsif ($increment and $increment =~ /^\-([0-9]+)$/) {
        $self->set("pcount", $self->get("pcount") - $1);
    }

    return $self->get("pcount") || 0;
}


=item run()

Run the queued commands

=cut

sub
run($)
{
    my ($self) = @_;
    my $select = $self->get("select");
    my $queueset = $self->get("queueset");
    my $fanout = $self->fanout();
    my @queueobjects = $queueset->get_list();

    # Spawning the initial fanout within the queue
    while ($self->pcount() < $fanout && @queueobjects) {
        $self->forkobj(shift(@queueobjects));
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
                }

                while ($self->pcount() < $fanout && @queueobjects) {
                    $self->forkobj(shift(@queueobjects));
                }
            }
        }
        &dprint("Invoking the timer\n");
        $self->timer();
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
    my $pid;

    &dprint("Spawning command: $command\n");
    $pid = open($fh, "$command |");
    $select->add($fh);

    &dprint("Created fileno: ". $fh->fileno() ."\n");

    $obj->set("fh", $fh);
    $obj->set("fileno", $fh->fileno());
    $obj->set("starttime", time());
    $obj->set("pid", $pid);
    $self->pcount("+1");
}

sub
closefh($)
{
    my ($self, $fh) = @_;
    my $queueset = $self->get("queueset");
    my $select = $self->get("select");
    my $fileno = $fh->fileno();

    &dprint("Closing fileno: $fileno\n");

    my $obj = $queueset->find("fileno", $fileno);
    if ($obj) {
        &dprint("closing out fileno: $fileno\n");

        $select->remove($fh);
        $fh->close();
        $obj->set("done", "1");
        $obj->del("fileno");
        $self->pcount("-1");
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
    my $wtime = $self->wtime();
    my $ktime = $self->ktime();

    foreach my $obj ($queueset->get_list()) {
        my $starttime = $obj->get("starttime");
        my $fileno = $obj->get("fileno");
        my $command = $obj->get("command");
        my $warning = $obj->get("warning");
        my $pid = $obj->get("pid");
        if (! $obj->get("done") and $fileno ) {
            if (! $warning and $wtime and $curtime > ($starttime + $wtime)) {
                &wprint("Process $pid still running ($command)\n");
                $obj->set("warning", 1);
            } elsif ($ktime and $curtime > ($starttime + $ktime)) {
                &wprint("Killing process $pid ($command)\n");
                my $fh = $obj->get("fh");
                kill("TERM", $pid);
                kill("INT", $pid);
                kill("KILL", $pid);
            }
        }
    }
}

1;
