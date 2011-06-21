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

    $output .= "Reconfigure DHCP services manually";

    return($output);
}

sub
summary()
{
    my $output;

    $output .= "Manage DHCP services and configuration";

    return($output);
}



sub
help()
{
    my ($self, $keyword) = @_;
    my $h;

    $h .= "USAGE:\n";
    $h .= "     node [command] [options] [targets]\n";
    $h .= "\n";
    $h .= "SUMMARY:\n";
    $h .= "        The DHCP command configures/reconfigures the DHCP services.\n";
    $h .= "COMMANDS:\n";
    $h .= "\n";
    $h .= "     The first argument MUST be the desired action you wish to take and after\n";
    $h .= "     the action, the order of the options and the targets is not specific.\n";
    $h .= "\n";
    $h .= "         update          Update the DHCP configuration, and restart the service\n";
    $h .= "         restart         Restart the DHCP service\n";
    $h .= "\n";

    return($h);
}


sub
exec()
{
    my ($self, $command, @args) = @_;
    my $dhcp = Warewulf::Provision::DhcpFactory->new();

    if ($command eq "update") {
        &nprint("Rebuilding the DHCP configuration\n");
        $dhcp->persist();
        &nprint("Done.\n");
    } elsif ($command eq "restart") {
        &nprint("Restarting the DHCP service\n");
        $dhcp->restart();
        &nprint("Done.\n");
    }

}



1;






