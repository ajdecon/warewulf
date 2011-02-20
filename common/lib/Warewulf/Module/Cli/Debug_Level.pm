#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#


package Warewulf::Module::Cli::Debug_Level;

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

    if ($debug_level) {
        &set_log_level($debug_level);
        &iprint("Debug level set to: $debug_level\n");
    }
}


sub
complete()
{
    my ($self) = @_;

    return("notice", "info", "debug");
}

sub
help()
{
    my ($self) = @_;
    my $output;

    $output .= "        This will set the default debugging/logging level for this shell. Valid\n";
    $output .= "        options include:\n";
    $output .= "\n";
    $output .= "            notice:     Only show normal usage messages\n";
    $output .= "            info:       Display increased verbosity\n";
    $output .= "            debug:      Debugging output\n";
    $output .= "\n";

    return($output);
}


1;
