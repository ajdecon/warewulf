#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#


package Warewulf::Module::Cli::Quiet;

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

    &set_log_level("WARNING");

    &iprint("Debug level: ". &get_log_level() ."\n");
}


sub
complete()
{
    my ($self) = @_;

    return;
}


sub
summary()
{
    my $output;

    $output .= "Only print warnings, and don't prompt when possible";

    return($output);
}


1;
