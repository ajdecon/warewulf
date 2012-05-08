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

use Warewulf::ACVars;
use Warewulf::Logger;
use Warewulf::Provision::Dhcp;
use Warewulf::DataStore;
use Warewulf::Network;
use Warewulf::SystemFactory;
use Warewulf::Util;
use Socket;

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


=item restart()

Restart the DHCP service

=cut

sub
restart()
{

    my $system = Warewulf::SystemFactory->new();

    if (!$system->chkconfig("dhcpd", "on")) {
        &eprint($system->output() ."\n");
    }
    if (! $system->service("dhcpd", "restart")) {
        &eprint($system->output() ."\n");
    }

}

=item persist()

This will update the DHCP file.

=cut

sub
persist()
{
    my $self = shift;
    my $sysconfdir = &Warewulf::ACVars::get("sysconfdir");

    if (! $self->get("FILE")) {
        &dprint("No configuration file present, so no DHCP configuration to persist\n");
        return;
    }

    if (&uid_test(0)) {
        my $datastore = Warewulf::DataStore->new();
        my $netobj = Warewulf::Network->new();
        my $config = Warewulf::Config->new("provision.conf");
        my $devname = $config->get("network device");
        my $ipaddr = $netobj->ipaddr($devname);
        my $netmask = $netobj->netmask($devname);
        my $network = $netobj->network($devname);
        my $config_template;
        my $dhcpd_contents;
        my %seen;

        if (! $ipaddr) {
            &wprint("Could not obtain IP address of this system!\n");
            &wprint("Check provision.conf 'network device'\n");
            &eprint("Not building DHCP configuration\n");
            return(1);
        }
        if (! $netmask) {
            &wprint("Could not obtain the netmask of this system!\n");
            &eprint("Not building DHCP configuration\n");
            return(1);
        }
        if (! $network) {
            &wprint("Could not obtain the base network of this system!\n");
            &eprint("Not building DHCP configuration\n");
            return(1);
        }

        if (-f "$sysconfdir/warewulf/dhcpd-template.conf") {
            open(DHCP, "$sysconfdir/warewulf/dhcpd-template.conf");
            while($line = <DHCP>) {
                $config_template .= $line;
            }
            close DHCP;
        } else {

            $config_template .= "allow booting;\n";
            $config_template .= "allow bootp;\n";
            $config_template .= "ddns-update-style interim;\n";
            $config_template .= "option routers default_router;\n";
            $config_template .= "filename \"/warewulf/gpxelinux.0\";\n";
            $config_template .= "not authoritative;\n";
            $config_template .= "\n";

            $config_template .= "subnet $network netmask $netmask {\n";
            $config_template .= "   not authoritative;\n";
            $config_template .= "   option subnet-mask $netmask;\n";
            $config_template .= "}\n";
            $config_template .= "\n";
            $config_template .= "# Node entries will follow below\n";
            $config_template .= "\n";

            if (! open(DHCP, "> $sysconfdir/warewulf/dhcpd-template.conf")) {
                &eprint("Could not save DHCP template file: $!\n");
                return();
            }
            print DHCP $config_template;
            close DHCP;
        }


        chomp($config_template);

        &dprint("Creating DHCPD configuration file header\n");
        $dhcpd_contents .= "# DHCPD Configuration written by Warewulf. Do not edit this file, rather\n";
        $dhcpd_contents .= "# edit the template in the Warewulf configuration directory.\n";
        $dhcpd_contents .= "\n";

        $dhcpd_contents .= $config_template;

        $dhcpd_contents .= "\n";
        $dhcpd_contents .= "group {\n";

        &dprint("Iterating through nodes\n");
        foreach my $n ($datastore->get_objects("node")->get_list()) {
            my $nodename = $n->nodename() || "undef";
            &dprint("Evaluating node: $nodename\n");
            my @bootservers = $n->get("bootserver");
            if (! @bootservers or scalar(grep { $_ eq $ipaddr} @bootservers)) {
                my ($master_ipv4_bin) = $n->get("master");
                my $master_ipv4_addr = $netobj->ip_unserialize($master_ipv4_bin);
                my $clustername = $n->cluster();
                my $domainname = $n->domain();
                my $domain;

                if ($clustername) {
                    if ($domain) {
                        $domain .= ".";
                    }
                    $domain .= $clustername;
                }
                if ($domainname) {
                    if ($domain) {
                        $domain .= ".";
                    }
                    $domain .= $domainname;
                }

                foreach my $devname ($n->netdevs_list()) {
                    my $hwaddr = $n->hwaddr($devname);
                    my $ipv4_addr = $n->ipaddr($devname);
                    my $gateway = $n->gateway($devname);

                    if (! $hwaddr) {
                        &dprint("Skipping $devname as it has no defined HWADDR\n");
                        next;
                    }

                    if (! $ipv4_addr) {
                        &dprint("Skipping $devname as it has no defined IPADDR\n");
                        next;
                    }

                    if (exists($seen{"NODESTRING"}) and exists($seen{"NODESTRING"}{"$nodename-$devname"})) {
                        my $redundant_node = $seen{"NODESTRING"}{"$nodename-$devname"};
                        &iprint("Skipping redundant node entry for $nodename-$devname already seen in $redundant_node)\n");
                        next;
                    }
                    if (exists($seen{"HWADDR"}) and exists($seen{"HWADDR"}{"$hwaddr"})) {
                        my $redundant_node = $seen{"HWADDR"}{"$hwaddr"};
                        &iprint("Skipping redundant HWADDR ($hwaddr) in $nodename-$devname (already seen in $redundant_node)\n");
                        next;
                    }
                    if (exists($seen{"IPADDR"}) and exists($seen{"IPADDR"}{"$ipv4_addr"})) {
                        my $redundant_node = $seen{"IPADDR"}{"$ipv4_addr"};
                        &iprint("Skipping redundant IPADDR ($ipv4_addr) in $nodename-$devname (already seen in $redundant_node)\n");
                        next;
                    }

                    if ($nodename and $ipv4_addr and $hwaddr) {
                        &dprint("Adding a host entry for: $nodename-$devname\n");

                        $dhcpd_contents .= "   host $nodename-$devname {\n";
                        $dhcpd_contents .= "      option host-name $nodename;\n";
                        if ($gateway) {
                            $dhcpd_contents .= "      option routers $gateway;\n";
                        }
                        if ($domain) {
                            $dhcpd_contents .= "      option domain-name \"$domain\";\n";
                        }
                        $dhcpd_contents .= "      hardware ethernet $hwaddr;\n";
                        $dhcpd_contents .= "      fixed-address $ipv4_addr;\n";
                        if ($master_ipv4_bin) {
                            $dhcpd_contents .= "      next-server $master_ipv4_addr;\n";
                        }
                        $dhcpd_contents .= "   }\n";

                        $seen{"NODESTRING"}{"$nodename-$devname"} = "$nodename-$devname";
                        $seen{"HWADDR"}{"$hwaddr"} = "$nodename-$devname";
                        $seen{"IPADDR"}{"$ipv4_addr"} = "$nodename-$devname";

                    } else {
                        &dprint("Skipping node '$nodename-$devname' due to insufficient information\n");
                    }
                }
            }
        }

        $dhcpd_contents .= "}\n";

        if ( 1 ) { # Eventually be smart about if this gets updated.
            my ($digest1, $digest2);
            my $system = Warewulf::SystemFactory->new();

            if ($self->get("FILE") and -f $self->get("FILE")) {
                $digest1 = digest_file_hex_md5($self->{"FILE"});
            }
            &iprint("Updating DHCP configuration\n");
            &dprint("Opening file ". $self->get("FILE") ." for writing\n");
            if (! open(FILE, ">". $self->get("FILE"))) {
                &eprint("Could not open ". $self->get("FILE") ." for writing: $!\n");
                return();
            }

            print FILE $dhcpd_contents;

            close FILE;
            $digest2 = digest_file_hex_md5($self->get("FILE"));
            if (! $digest1 or $digest1 ne $digest2) {
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
