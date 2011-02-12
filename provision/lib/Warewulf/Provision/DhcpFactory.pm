# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Provision::DhcpFactory.pm 168 2011-01-04 01:26:47Z gmk $
#

package Warewulf::Provision::DhcpFactory;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::Config;
use DBI;


=head1 NAME

Warewulf::Provision::DhcpFactory - DHCP interface

=head1 ABOUT

The Warewulf::Provision::DhcpFactory interface simplies typically used DB calls and operates on
Warewulf::Objects and Warewulf::ObjectSets for simplistically integrating
with native Warewulf code.

=head1 SYNOPSIS

    use Warewulf::Provision::DhcpFactory;

    my $db = Warewulf::Provision::DhcpFactory->new($type);

=item new($type)

Create the object of given type. If no type is passed it will read from the 
configuration file 'provision.conf' and use the paramater 'dhcp server' as
the type.

=cut
sub
new($$)
{
    my $proto = shift;
    my $type = shift;
    my $mod_name;
    my $mod_base = "Warewulf::Provision::Dhcp::";

    if (! $type) {
        my $config = Warewulf::Config->new("provision.conf");
        $type = $config->get("dhcp server") || "isc";
    }

    if ($type =~ /^([a-zA-Z0-9\-_\.]+)$/) {

        $mod_name = $mod_base . ucfirst(lc($1));

        if (! exists($modules{$mod_name})) {
            &dprint("Loading object name: $mod_name\n");
            eval "require $mod_name";
            if ($@) {
                &cprint("Could not load '$mod_name'!\n");
                exit 1;
            }
            $modules{$mod_name} = 1;
        }

        &dprint("Getting a new object from $mod_name\n");

        my $obj = eval "$mod_name->new(\@_)";

        &dprint("Got an object: $obj\n");

        return($obj);
    } else {
        &eprint("DHCP server name contains illegal characters.\n");
    }

    return();
}

=head1 SEE ALSO

Warewulf::Provision::Dhcp

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut




1;

