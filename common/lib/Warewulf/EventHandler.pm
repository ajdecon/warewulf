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
my $disable;
my $events_loaded;

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

    if ($events_loaded) {
        &dprint("Events already loaded, skipping...\n");
    } else {
        $events_loaded = 1;
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

                        &iprint("Loading event handler: $name\n");
                        eval {
                            no warnings;
                            local $SIG{__WARN__} = sub { 1; };
                            require $file_clean;
                        };
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

    &dprint("Registering event '$event' for ". ref($self) ."\n");

    push(@{$events{"$event_name"}}, $func_ref);

}


=item disable()

Disable all events

=cut
sub
disable()
{
    my ($self) = @_;

    $disable = 1;

}


=item enable()

Enable all events (this is the default, so it toggles back on after
disable() has been called).

=cut
sub
enable()
{
    my ($self) = @_;

    $disable = undef;

}


=item handle($trigger_name, @argument_list)

Run all of the events that have registered the defined trigger name

=cut
sub
handle()
{
    my ($self, $event, @arguments) = @_;
    my $event_name = uc($event);

    if ($disable) {
        &iprint("Event handler is disabled, not running any events for: $event_name\n");
    } else {
        if (exists($events{"$event_name"})) {
            &dprint("Handling events for '$event_name'\n");
            foreach my $func (@{$events{"$event_name"}}) {
                &$func(@arguments);
            }
        } else {
            &dprint("No events registered for: $event_name\n");
        }
        if ($event_name =~ /^([^\.]+)\.([^\.]+)$/) {
            my $type = $1;
            my $action = $2;
            if (exists($events{"$type.*"})) {
                &dprint("Handling events for '$type.*'\n");
                foreach my $func (@{$events{"$type.*"}}) {
                    &$func(@arguments);
                }
            }
            if (exists($events{"*.$action"})) {
                &dprint("Handling events for '*.$action'\n");
                foreach my $func (@{$events{"*.$action"}}) {
                    &$func(@arguments);
                }
            }
        } else {
            &dprint("event_name couldn't be parsed for type.action\n");
        }
    }
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

