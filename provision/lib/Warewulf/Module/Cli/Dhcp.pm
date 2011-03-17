#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#



package Warewulf::Module::Cli::Dhcp;

use Warewulf::Logger;
use Warewulf::Provision::DhcpFactory;

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
description()
{
    my $output;

    $output .= "Reconfigure DHCP services for this host manually";

    return($output);
}

sub
summary()
{
    my $output;

    $output .= "Configure/Reconfigure DHCP services";

    return($output);
}



sub
help()
{
    my ($self, $keyword) = @_;
    my $output;

    $output .= "        The DHCP command will reconfigure the DHCP service for this host\n";

    return($output);
}


sub
exec()
{
    my ($self, @args) = @_;

    &nprint("Rebuilding the DHCP configuration\n");
    my $dhcp = Warewulf::Provision::DhcpFactory->new();
    $dhcp->persist();
    &nprint("Done.\n");

}



1;






