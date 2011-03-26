# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Isc.pm 50 2010-11-02 01:15:57Z gmk $
#

package Warewulf::Provision::Dhcp::Isc;

use Warewulf::Logger;
use Warewulf::Provision::Dhcp;
use Warewulf::DataStore;
use Warewulf::Network;
use Warewulf::SystemFactory;
use Warewulf::Util;
use Socket;
use Digest::file qw(digest_file_hex);

our @ISA = ('Warewulf::Provision::Dhcp');

=head1 NAME

Warewulf::Provision::Dhcp::Isc - Warewulf's ISC DHCP server interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Provision::Dhcp::Isc;

    my $obj = Warewulf::Provision::Dhcp::Isc->new();


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
    my $config = Warewulf::Config->new("provision.conf");

    my @files = ('/etc/dhcp/dhcpd.conf', '/etc/dhcpd.conf');

    if (my $file = $config->get("dhcpd config file")) {
        &dprint("Using the DHCPD configuration file as defined by provision.conf\n");
        if ($file =~ /^([a-zA-Z0-9_\-\.\/]+)$/) {
            $self->set("FILE", $1);
        } else {
            &eprint("Illegal characters in path: $file\n");
        }

    } elsif (! $self->get("FILE")) {
        # First look to see if we can find an existing dhcpd.conf file
        foreach my $file (@files) {
            if ($file =~ /^([a-zA-Z0-9_\-\.\/]+)$/) {
                my $file_clean = $1;
                if (-f $file_clean) {
                    $self->set("FILE", $file_clean);
                    &dprint("Found DHCPD configuration file: $file_clean\n");
                }
            } else {
                &eprint("Illegal characters in path: $file\n");
            }
        }
        # If we couldn't find one, lets set it to a sane default and hope for the best
        if (! $self->get("FILE")) {
            &dprint("Probing dhcpd looking for a default config path\n");
            if (-x "/usr/sbin/dhcpd") {
                open(CONF, "strings /usr/sbin/dhcpd | grep '/dhcpd.conf' | grep '^/etc/' |");
                my $file = <CONF>;
                chomp($file);
                if ($file =~ /^([a-zA-Z0-9_\-\.\/]+)$/) {
                    $self->set("FILE", $1);
                } else {
                    &eprint("Illegal characters in path: $file\n");
                }
            }
        }
    }

    return($self);
}


=item persist()

This will update the DHCP file.

=cut
sub
persist()
{
    my $self = shift;

    if (&uid_test(0)) {
        my $datastore = Warewulf::DataStore->new();
        my $netobj = Warewulf::Network->new();
        my $config = Warewulf::Config->new("provision.conf");
        my $netdev = $config->get("network device");
        my $config_template;
        my $dhcpd_contents;

        if (-f "/etc/warewulf/dhcpd-template.conf") {
            open(DHCP, "/etc/warewulf/dhcpd-template.conf");
            while($line = <DHCP>) {
                $config_template .= $line;
            }
            close DHCP;
        } else {
            my $config = Warewulf::Config->new("provision.conf");
            my $netobj = Warewulf::Network->new();
            my $netdev = $config->get("network device");
            my $ipaddr = $netobj->ipaddr($netdev);
            my $netmask = $netobj->netmask($netdev);
            my $network = $netobj->network($netdev);

            $config_template .= "allow booting;\n";
            $config_template .= "allow bootp;\n";
            $config_template .= "ddns-update-style interim;\n";
            $config_template .= "option domain-name-servers dns_servers;\n";
            $config_template .= "option routers default_router;\n";
            $config_template .= "filename \"/warewulf/gpxelinux.0\";\n";
            $config_template .= "not authoritative;\n";
            $config_template .= "\n";

            $config_template .= "subnet $network netmask $netmask {\n";
            $config_template .= "   not authoritative;\n";
            $config_template .= "   option subnet-mask $netmask;\n";
            $config_template .= "   option routers $ipaddr;\n";
            $config_template .= "}\n";
            $config_template .= "\n";
            $config_template .= "# Node entries will follow below\n";
            $config_template .= "\n";

            if (! open(DHCP, "> /etc/warewulf/dhcpd-template.conf")) {
                &eprint("Could not save DHCP template file: $!\n");
                return();
            }
            print DHCP $config_template;
            close DHCP;
        }


        chomp($config_template);

        $dhcpd_contents .= "# DHCPD Configuration written by Warewulf. Do not edit this file, rather\n";
        $dhcpd_contents .= "# edit the template in the Warewulf configuration directory.\n";
        $dhcpd_contents .= "\n";

        $dhcpd_contents .= $config_template;

        $dhcpd_contents .= "\n";
        $dhcpd_contents .= "group {\n";

        # Get all nodes that either have no master lookup set, or if they are set to any of the
        # local IP addresses on this system
        foreach my $n ($datastore->get_objects("node", "master", "UNDEF", $netobj->list_ipaddrs())->get_list()) {
            my $name = $n->get("name");
            my $cluster = $n->get("cluster");
            my $domain = $n->get("domain");
            my @hwaddr = $n->get("hwaddr");
            my $master_ipv4 = $netobj->ip_unserialize($n->get("master"));
            my $node_ipv4 = $netobj->ip_unserialize($n->get("ipaddr"));

            &dprint("Adding a host entry for: $name\n");

            if ($name and $node_ipv4 and $hwaddr[0]) {
                $dhcpd_contents .= "   host $name {\n";
                $dhcpd_contents .= "      option host-name $name;\n";
                $dhcpd_contents .= "      hardware ethernet $hwaddr[0];\n";
                $dhcpd_contents .= "      fixed-address $node_ipv4;\n";
                if ($master[0]) {
                    $dhcpd_contents .= "      next-server $master_ipv4;\n";
                }
                $dhcpd_contents .= "   }\n";
            } else {
                &dprint("Skipping node '$name' due to insufficient information\n");
            }
        }

        $dhcpd_contents .= "}\n";

        if ( 1 ) { # Eventually be smart about if this gets updated.
            my ($digest1, $digest2);
            my $system = Warewulf::SystemFactory->new();

            $digest1 = digest_file_hex($self->{"FILE"}, "MD5");
            &iprint("Updating DHCP configuration\n");
            &dprint("Opening file ". $self->{"FILE"} ." for writing\n");
            if (! open(FILE, ">". $self->{"FILE"})) {
                &eprint("Could not open ". $self->{"FILE"} ." for writing: $!\n");
                return();
            }

            print FILE $dhcpd_contents;

            close FILE;
            $digest2 = digest_file_hex($self->{"FILE"}, "MD5");
            if ($digest1 ne $digest2) {
                &dprint("Restarting DHCPD service\n");
                if (! $system->service("dhcpd", "restart")) {
                    &eprint($system->output() ."\n");
                }
            } else {
                &dprint("Not restarting DHCPD service\n");
            }
            if (!$system->chkconfig("dhcpd", "on")) {
                &eprint($system->output() ."\n");
            }
        } else {
            &iprint("Not updating DHCP configuration: files are current\n");
        }
    } else {
        &iprint("Not updating DHCP configuration: user not root\n");
    }

    return();
}

=back

=head1 SEE ALSO

Warewulf::Provision::Dhcp

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
