# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: ParallelCmd.pm 50 2010-11-02 01:15:57Z gmk $
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
    $o->fanout(32);
    for (my $i=1; $i<= 100; $i++) {
        $o->queue("sleep 1; echo '$i done'");
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

    $self->set("select", $select);

    return($self);
}

=item queue()

Add a command to the queue to run in parallel

=cut

sub
queue($)
{
    my ($self, $command) = @_;

    &dprint("Adding command to queue: $command\n");
    # Not using the OBJECT::add function, because it is too smart and doesn;t
    # add redundant entries.
    push(@{$self->{"QUEUE"}}, $command);

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
    my @queue = $self->get("queue");
    my $fanout = $self->get("fanout") || 64;
    my $cmdobjs = Warewulf::ObjectSet->new();

    $cmdobjs->index("fileno");

    $self->set("cmdobjs", $cmdobjs);

    # Spawning the initial fanout within the queue
    for (my $i=1; $i <= $fanout && $i <= scalar(@queue); $i++) {
        $self->forkcmd(shift(@queue));
    }

    #while (my @ready = $select->can_read("2")) {
    my $timer = 1;
    while ($select->count() > 0) {
        my $timeleft = $timer+$time - time;
        my @ready = $select->can_read($timeleft);
        &dprint("can_read($timeleft) engaged\n");
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
                    $self->endcmd($fh);
                    # Closed one file handle, so now lets queue the next in the array
                    # if it exists.
                    if (scalar(@queue)) {
                        $self->forkcmd(shift(@queue));
                    }
                }
            }
        } else {
            &dprint("Invoking the warnings\n");
            $self->warnings();
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
forkcmd($)
{
    my ($self, $command) = @_;
    my $cmdObjs = $self->get("cmdobjs");
    my $cmdObj = Warewulf::Object->new();
    my $select = $self->get("select");
    my $fh;

    &dprint("Spawning command: $command\n");
    open($fh, "$command |");
    $select->add($fh);

    $cmdObj->set("command", $command);
    $cmdObj->set("fh", $fh);
    $cmdObj->set("fileno", $fh->fileno());
    $cmdObj->set("warningtime", time());
    $cmdObjs->add($cmdObj);
}

sub
endcmd($)
{
    my ($self, $fh) = @_;
    my $select = $self->get("select");
    my $cmdObjs = $self->get("cmdobjs");
    my $fileno = $fh->fileno();

    &dprint("closing out fileno: $fileno\n");
    $select->remove($fh);
    $fh->close();

    $cmdObjs->del("fileno", $fileno) or print "ERROR: Did not remove the object\n";
}

sub
warnings($)
{
    my ($self) = @_;
    my $cmdObjs = $self->get("cmdobjs");
    my $wtime = $self->get("wtime") || 15;
    &dprint("called warnings()\n");

    foreach my $cmdObj ($cmdObjs->get_list()) {
        my $runtime = time - $cmdObj->get("warningtime");
        if ($runtime >= $wtime) {
            my $fh = $cmdObj->get("fh");
            my $fileno = $cmdObj->get("fileno");
            my $command = $cmdObj->get("command");
            $cmdObj->set("warningtime", time);
            &dprint("fileno: $fileno, runtime: $runtime\n");
            &wprint("Command still running: $command\n");
        }
    }
}



1;
