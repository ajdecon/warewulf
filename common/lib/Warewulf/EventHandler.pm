# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: EventHandler.pm 83 2010-12-09 22:13:21Z gmk $
#

package Warewulf::EventHandler;

use Warewulf::Util;
use Warewulf::Logger;
use File::Basename;

my $singleton;

=head1 NAME

Warewulf::EventHandler - Database interface

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::EventHandler;

    my $obj = Warewulf::EventHandler->new();

    sub
    event_callback
    {
        my ($self, @arguments) = @_;

        print STDERR "Arguments: @arguments\n";
    }

    $obj->register("error.print", \&event_callback);

TRIGGERING EVENTS:

    use Warewulf::EventHandler;

    my $obj = Warewulf::EventHandler->new();

    $obj->handle("error.print", "arg1", "arg2");

API for subscription and events:

    Event string        Argument list

    node.boot           node_object
    node.down           node_object
    node.add            node_object
    node.modify         node_object
    node.ready          node_object
    node.error          node_object
    node.warning        node_object

=item new()

Create the object.

=cut

sub
new($)
{
    my $proto = shift;
    my $type = shift;
    my $class = ref($proto) || $proto;

    if (! defined($singleton)) {
        bless($singleton, $class);
    }

    return($singleton);
}

=item register($trigger_name, $func_ref)

Subscribe an event callback by its trigger name

=cut
sub
register()
{
    my ($self, $event, $func_ref) = @_;

}


=item handle($trigger_name, @argument_list)

Run all of the events that have registered the defined trigger name

=cut
sub
handle()
{
    my ($self, $event, $func_ref) = @_;

}



=back

=head1 SEE ALSO

Warewulf::Module

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;

