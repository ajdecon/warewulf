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

my %events;

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

    $obj->eventloader();
    $obj->handle("error.print", "arg1", "arg2");

API registration recommendation:

    There is nothing limiting this API to what is defined here but this is
    a sane starting point as to what events should be used.

    Event string        Argument list

    node.boot           node_object
    node.down           node_object
    node.add            node_object
    node.modify         node_object
    node.ready          node_object
    node.error          node_object
    node.warning        node_object
    program.start
    program.exit
    program.error
    [appname].start
    [appname].exit
    [appname].error

=item new()

Create the object.

=cut

sub
new($)
{
    my $proto = shift;
    my $type = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless($self, $class);

    &dprint("Created new EventHandler object\n");

    return($self);
}

sub
eventloader()
{
    my $self = shift;

    foreach my $path (@INC) {
        if ($path =~/^(\/[a-zA-Z0-9_\-\/\.]+)$/) {
            &dprint("Module load path: $path\n");
            foreach my $file (glob("$path/Warewulf/Event/*.pm")) {
                &dprint("Found $file\n");
                if ($file =~ /^([a-zA-Z0-9_\-\/\.]+)$/) {
                    my $file_clean = $1;
                    my ($name, $tmp, $keyword);

                    $name = "Warewulf::Event::". basename($file_clean);
                    $name =~ s/\.pm$//;

                    if (! exists($loaded{"$name"})) {
                        &dprint("Module load file: $file_clean\n");
                        eval "require '$file_clean'";
                        if ($@) {
                            &wprint("Caught error on module load: $@\n");
                        }
                    }
                }
            }
        }
    }
}


=item register($trigger_name, $func_ref)

Subscribe an event callback by its trigger name

=cut
sub
register()
{
    my ($self, $event, $func_ref) = @_;
    my $event_name = uc($event);



    push(@{$events{"$event_name"}}, $func_ref);

}


=item handle($trigger_name, @argument_list)

Run all of the events that have registered the defined trigger name

=cut
sub
handle()
{
    my ($self, $event, @arguments) = @_;
    my $event_name = uc($event);

    if (exists($events{"$event_name"})) {
        &dprint("Handling events for '$event_name'\n");
        foreach my $func (@{$events{"$event_name"}}) {
            &$func(@arguments);
        }
    }
}


&set_log_level("DEBUG");

my $obj = Warewulf::EventHandler->new();
$obj->eventloader();
$obj->handle("moo");


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

