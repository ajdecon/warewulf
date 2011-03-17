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
    my $self = shift;
    my $onoff = uc(shift);
    my $events = Warewulf::EventHandler->new();

    if ($onoff eq "ENABLE") {
        &nprint("Enabling the Warewulf Event Handler\n");
        $events->enable();
    } elsif ($onoff eq "DISABLE") {
        &nprint("Disabling the Warewulf Event Handler\n");
        $events->disable();
    }
}


sub
complete()
{
    my ($self) = @_;

    return("enable", "disable", "run", "clear", "show");
}



sub
options()
{
    my %hash;

    $hash{"enable"} = "Enable the event handler (default)";
    $hash{"disable"} = "Disable events from occuring (note they will still be queued)";
    $hash{"run"} = "Run the event queue (unavailable)";
    $hash{"clear"} = "Clear the event queue (unavailable)";
    $hash{"show"} = "Show the event queue (unavailable)";

    return(%hash);
}

sub
summary()
{
    my $output;

    $output .= "Control how events are handled";

    return($output);
}

sub
description()
{
    my $output;

    $output .= "Warewulf may have events configured to run automatically based on triggers\n";
    $output .= "that are automatically added to Warewulf via subpackages.\n";

    return($output);
}





sub
help()
{
    my ($self) = @_;
    my $output;

    $output .= "        Globally enable or disable the event handler.\n";
    $output .= "\n";

    return($output);
}


1;
