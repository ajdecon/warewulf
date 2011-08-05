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


=item run()

Run the queued commands

=cut

sub
run($)
{
    my ($self) = @_;
    my $select = $self->get("select");
    my @queue = @{$self->{"QUEUE"}};
    my $fanout = $self->get("fanout") || 64;

    for(my $i=0; $i <= $fanout and $i <= scalar(@queue); $i++) {
        my $command = shift(@queue);
        my $fh;
        &dprint("Spawning command: $command\n");
        open($fh, "$command |");
        $select->add($fh);
    }

    while(my @ready = $select->can_read()) {
        foreach my $fh (@ready) {
            while(<$fh>) {
                print $_;
            }
            $select->remove($fh);
            $fh->close();
            # Closed one file handle, so now lets queue the next in the array
            # if it exists.
            if (@queue) {
                my $fh;
                my $command = shift(@queue);

                &dprint("Spawning command: $command\n");
                open($fh, "$command |");
                $select->add($fh);
            }
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


1;
