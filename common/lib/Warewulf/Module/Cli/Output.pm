#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#


package Warewulf::Module::Cli::Output;

use Warewulf::Logger;

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
    my $debug_level = uc(shift);

    if ($debug_level eq "QUIET") {
        &set_log_level("WARNING");
    } elsif ($debug_level eq "NORMAL") {
        &set_log_level("NOTICE");
    } elsif ($debug_level eq "VERBOSE") {
        &set_log_level("INFO");
    } elsif ($debug_level eq "DEBUG") {
        &set_log_level("DEBUG");
    } elsif ($debug_level) {
        &eprint("Invalid output level: $debug_level\n");
    }
    &iprint("Debug level: ". &get_log_level() ."\n");
}


sub
complete()
{
    my ($self) = @_;

    return("quiet", "normal", "verbose", "debug");
}

sub
options()
{
    my %hash;

    $hash{"quiet"} = "Suppress all messages but warnings and errors";
    $hash{"normal"} = "Only show normal usage messages";
    $hash{"verbose"} = "Display increased verbosity";
    $hash{"debug"} = "Debugging output";

    return(%hash);
}

sub
description()
{
    my $output;

    $output .= "This will set the debugging/logging level for this shell.";

    return($output);
}

sub
summary()
{
    my $output;

    $output .= "This will set the debugging/logging level";

    return($output);
}


1;
