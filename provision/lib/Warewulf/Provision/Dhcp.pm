# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Dhcp.pm 50 2010-11-02 01:15:57Z gmk $
#

package Warewulf::Dhcp;

use Warewulf::Logger;
use Warewulf::Object;
use Warewulf::DataStore;
use Warewulf::Network;
use Socket;

our @ISA = ('Warewulf::Object');

&set_log_level("DEBUG");

=head1 NAME

Warewulf::Dhcp - Warewulf's general object instance object interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Dhcp;

    my $obj = Warewulf::Dhcp->new();


=head1 METHODS

=over 12
=cut


=item new()

The new constructor will create the object that references configuration the
stores.

=cut
sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = ();

    $self = {};

    bless($self, $class);

    return $self->init(@_);
}


sub
init()
{
    my $self = shift;

    # List of files to use, default is the first one if none are found.
    my @files = ('/etc/dhcpd.conf');

    if (! $self->get("FILE")) {
        # First look to see if we can find an existing dhcpd.conf file
        foreach my $file (@files) {
            if (-f $file) {
                $self->set("FILE", $file);
                &dprint("Found DHCPD configuration file: $file\n");
            }
        }
        # If we couldn't find one, lets set it to a sane default and hope for the best
        if (! $self->get("FILE")) {
            $self->set("FILE", $files[0]);
            &dprint("Setting default DHCPD configuration file to: $files[0]\n");
        }
    }

    return($self);
}


sub
persist()
{
    my $self = shift;
    my $datastore = Warewulf::DataStore->new();
    my $config = Warewulf::Config->new("provision.conf");
    my $netdev = $config->get("network device");
    my @local_addresses;

    foreach my $dev (&get_interfaces) {
        if (my $ip = &get_interface_address($dev)) {
            push(@local_addresses, $ip);
        }
    }

    open(FILE, ">". $self->{"FILE"});

    print FILE "# DHCPD Configuration written by Warewulf.\n";
    print FILE "\n";
    print FILE "allow booting;\n";
    print FILE "allow bootp;\n";
    print FILE "ddns-update-style interim;\n";
    print FILE "option domain-name-servers dns_servers;\n";
    print FILE "option routers default_router;\n";
    print FILE "filename \"pxelinux.0\";\n";
    print FILE "not authoritative;\n";
    print FILE "\n";

    print FILE "subnet 192.168.200.0 netmask 255.255.255.0 {\n";
    print FILE "   not authoritative;\n";
    print FILE "   option subnet-mask 255.255.255.0;\n";
    print FILE "   option routers 192.168.200.1;\n";
    print FILE "}\n";
    print FILE "\n";

    print FILE "group {\n";

    # Get all nodes that either have no master lookup set, or if they are set to any of the
    # local IP addresses on this system
    foreach my $n ($datastore->get_objects("node", "master", "NULL", @local_addresses)->get_list()) {
        my $name = $n->get("name");
        my $cluster = $n->get("cluster");
        my $domain = $n->get("domain");
        my @master = $n->get("master");
        my @hwaddr = $n->get("hwaddr");
        my @ipaddr = $n->get("ipaddr");

        if ($name) {
            print FILE "   host $name {\n";
            print FILE "      option host-name $name;\n";
            print FILE "      hardware ethernet $hwaddr[0];\n";
            print FILE "      fixed-address $ipaddr[0];\n";
            if ($master[0]) {
                print FILE "      next-server $master[0];\n";
            }
            print FILE "   }\n";
        }
    }

    print FILE "}\n";

    close FILE;

    return();
}



my $obj = Warewulf::Dhcp->new();

$obj->persist();


=back

=head1 SEE ALSO

Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
