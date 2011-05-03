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
help()
{
    my $h;

    $h .= "SUMMARY:\n";
    $h .= "     The output command sets the output level of the shell.\n";
    $h .= "\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     quiet       Only print warnings and errors\n";
    $h .= "     normal      Normal output of notifications, warnings and errors\n";
    $h .= "     verbose     Including verbose messages over normal\n";
    $h .= "     debug       Print all messages possible\n";
    $h .= "\n";
    $h .= "EXAMPLES:\n";
    $h .= "\n";
    $h .= "     Warewulf> output debug\n";
    $h .= "     Warewulf> output normal\n";
    $h .= "\n";

    return($h);
}


sub
summary()
{
    my $output;

    $output .= "This will set the debugging/logging level";

    return($output);
}


1;
