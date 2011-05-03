#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#


package Warewulf::Module::Cli::Events;

use Warewulf::Logger;
use Warewulf::EventHandler;

our @ISA = ('Warewulf::Module::Cli');


sub
new()
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless($self, $class);

    return $self;
}

sub
exec()
{
    my ($self, $arg) = @_;
    my $events = Warewulf::EventHandler->new();

    if (uc($arg) eq "ENABLE") {
        &nprint("Enabling the Warewulf Event Handler\n");
        $events->enable();
    } elsif (uc($arg) eq "DISABLE") {
        &nprint("Disabling the Warewulf Event Handler\n");
        $events->disable();
    }
}


sub
complete()
{
    my ($self) = @_;

    return("enable", "disable");
}


sub
help()
{
    my $h;

    $h .= "SUMMARY:\n";
    $h .= "     Control how/if events are handled.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     enable      Enable all events for this shell (default)\n";
    $h .= "     disable     Disable the event handler\n";
    $h .= "\n";

    return($h);
}

sub
summary()
{
    my $output;

    $output .= "Control how events are handled";

    return($output);
}


1;
