# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#

package Warewulf::Node;

use Warewulf::Object;
use Warewulf::ObjectSet;
use Warewulf::Logger;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::Node - Warewulf's Node object interface.

=head1 SYNOPSIS

    use Warewulf::Node;

    my $obj = Warewulf::Node->new();
    $o->name("test0000");

    $o->hwaddr("eth0", "00:00:00:00:00:00");
    $o->ipaddr("eth0", "10.10.10.10");
    $o->hwaddr("eth1", "00:00:00:00:00:11");
    $o->ipaddr("eth1", "10.10.20.10");

    foreach my $names ($o->netdevs()) {
        print "->$names<-\n";
    }

    printf("%s: %s\n", $o->name, $o->hwaddr("eth0"));
    printf("%s: %s\n", $o->name, $o->ipaddr("eth0"));
    printf("%s: %s\n", $o->name, $o->ipaddr("eth1"));

=head1 DESCRIPTION

The C<Warewulf::Node> object acts as a container for all members and
sub-objects needed to describe a Node.  This includes names, groups,
network devices, etc.  This object provides methods for querying and
modifying all members of Node objects.

=head1 METHODS

=over 4

=item new()

Create and return a new Node instance.

=cut

sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = ();

    $self = $class->SUPER::new();
    bless($self, $class);

    return $self->init(@_);
}


=item name($nodename, $clustername, $domainname)

Get or set the name of the node.  Because nodes can be part of multiple
clusters or sites, the name itself is made up of several other object members
(nodename, cluster, domain).  When setting any of these, the node's canonical
name is updated appropriately.

As a shortcut, you can set these also by supplying arguments here.  This is
mostly for backward compatibility.

In a list context, this method returns all known names for the C<Node>.  In a
scalar context, it returns the most complete name.

=cut

sub
name()
{
    my $self = shift;
    my @names;

    if (scalar(@_) && defined($_[0])) {
        &dprint("Setting nodename: $_[0]\n");
        $self->nodename($_[0]);
        shift(@_);
    }
    if (scalar(@_) && defined($_[0])) {
        &dprint("Setting cluster name: $_[0]\n");
        $self->cluster($_[0]);
        shift(@_);
    }
    if (scalar(@_) && defined($_[0])) {
        &dprint("Setting domain name: $_[0]\n");
        $self->domain($_[0]);
        shift(@_);
    }

    @names = $self->get("name");

    return ((wantarray()) ? (@names) : ($names[-1]));
}


=item nodename($string)

Set or return the nodename of this object.

=cut

sub
nodename()
{
    my $self = shift;
    my $nodename = $self->prop("nodename", qr/^([a-zA-Z0-9_\-]+)$/, @_);

    if (scalar(@_)) {
        &dprint(((defined($_[0])) ? ("Set nodename to: $_[0]\n") : ("Unset nodename\n")));
        $self->genname();
    }
    return $nodename;
}



=item cluster($string)

Set or return the cluster of this object.

=cut

sub
cluster()
{
    my $self = shift;
    my $cluster = $self->prop("cluster", qr/^([a-zA-Z0-9_\-]+)$/, @_);

    if (scalar(@_)) {
        &dprint(((defined($_[0])) ? ("Set cluster name to: $_[0]\n") : ("Unset cluster name\n")));
        $self->genname();
    }
    return $cluster;
}


=item domain($string)

Set or return the domain of this object.

=cut

sub
domain()
{
    my $self = shift;
    my $domain = $self->prop("domain", qr/^([a-zA-Z0-9_\-\.]+)$/, @_);

    if (scalar(@_)) {
        &dprint(((defined($_[0])) ? ("Set domain name to: $_[0]\n") : ("Unset domain name\n")));
        $self->genname();
    }
    return $domain;
}


=item groups(@strings)

Set or return the groups of this object.

=cut

sub
groups()
{
    my ($self, @strings) = @_;
    my $key = "groups";

    if (@strings) {
        my $name = $self->get("name");
        my @newgroups;

        foreach my $string (@strings) {
            if ($string =~ /^([a-zA-Z0-9_\.\-]+)$/) {
                &dprint("Object $name set $key += '$1'\n");
                push(@newgroups, $1);
            } else {
                &eprint("Invalid characters to set $key += '$string'\n");
            }
            $self->set($key, @newgroups);
        }
    }

    return $self->get($key);
}


=item groupadd(@strings)

Add a group or list of groups to the current object.

=cut

sub
groupadd()
{
    my ($self, @strings) = @_;
    my $key = "groups";

    if (@strings) {
        my $name = $self->get("name");

        foreach my $string (@strings) {
            if ($string =~ /^([a-zA-Z0-9_\.\-]+)$/) {
                &dprint("Object $name set $key += '$1'\n");
                $self->add($key, $1);
            } else {
                &eprint("Invalid characters to set $key += '$string'\n");
            }
        }
    }

    return $self->get($key);
}


=item groupdel(@strings)

Delete a group or list of groups to the current object.

=cut

sub
groupdel()
{
    my ($self, @strings) = @_;
    my $key = "groups";

    if (@strings) {
        my $name = $self->get("name");
        $self->del($key, @strings);
        &dprint("Object $name del $key -= @strings\n");
    }

    return($self->get($key));
}


=item canonicalize()

Check and update the object if necessary. Returns the number of changes made.

=cut

sub
canonicalize()
{
    my ($self) = @_;
    my $netdevs = $self->get("netdevs");
    my $nodename = $self->get("nodename");
    my $name = $self->get("name");
    my $changed = 0;

    if ($netdevs) {
        if (ref($netdevs) eq "ARRAY") {
            &iprint("Converting netdev array to ObjectSet\n");
            my $new_netdevs = Warewulf::ObjectSet->new();
            foreach my $n (@{$netdevs}) {
                bless($n, "Warewulf::Object");
                $self->add("_ipaddr", $n->get("ipaddr"));
                $self->add("_hwaddr", $n->get("hwaddr"));
                $new_netdevs->add($n);
            }
            $self->set("netdevs", $new_netdevs);
            $changed++;
        } elsif (ref($netdevs) eq "Warewulf::DSO::Netdev") {
            my $new_netdevs = Warewulf::ObjectSet->new();
            my $n = $netdevs;
            bless($n, "Warewulf::Object");
            $new_netdevs->add($n);
            $self->set("netdevs", $new_netdevs);
            $changed++;
        }
    } else {
        my $new_netdevs = $self->get("_netdevset");
        if ($new_netdevs) {
            &iprint("Moving _netdevset netdevs\n");
            $self->set("netdevs", $new_netdevs);
            $self->del("_netdevset");
            $changed++;
        }
    }
    if ($name and ! $nodename) {
        &iprint("Updating name array ($name): ". join(",", split(/\./, $name)) ."\n");
        $self->name(split(/\./, $name));
        $changed++;
    }
    return($changed);
}


=item netdevs($match)

Return the netdev ObjectSet for this node object. If a device name is passed
it will return just the netdev Object for that device.

=cut

sub
netdevs()
{
    my ($self, $match) = @_;
    my $netdevs;
    my @device_names;

    $netdevs = $self->get("netdevs");

    if ($netdevs and ref($netdevs) ne "Warewulf::ObjectSet") {
        &wprint("Temporarily canonicalizing node Object\n");
        $self->canonicalize();
        $netdevs = $self->get("netdevs");
    }

    if (! $netdevs) {
        $netdevs = $self->set("netdevs", Warewulf::ObjectSet->new());
    }

    if ($match) {
        return $netdevs->find("name", $match);
    } else {
        return $netdevs;
    }
}

=item netdevs_list()

Return a list of network device names.  This is just a convenience wrapper to
match up with hwaddr_list() and ipaddr_list().

=cut

sub
netdevs_list()
{
    my ($self) = @_;

    return $self->netdevs()->get_list_entries("name");
}

=item netdev_get_add($devname)

Find or create the netdev object for this node of a given device name.

=cut

sub
netdev_get_add()
{
    my ($self, $devname) = @_;
    my $netdev;

    if (!($devname = &validate_netdev_name($devname))) {
        return undef;
    }
    $netdev = $self->netdevs($devname);
    if (! $netdev) {
        $netdev = Warewulf::Object->new();
        $netdev->set("name", $devname);
        $self->netdevs()->add($netdev);
    }
    return $netdev;
}


=item netdel($devname)

Delete a network device from the C<Node>

=cut

sub
netdel()
{
    my ($self, $devname) = @_;
    my $netdev;

    if (!($devname = &validate_netdev_name($devname))) {
        return undef;
    }
    $netdev = $self->netdevs($devname);
    if ($netdev) {
        my $nodename = $self->nodename() || "UNDEF";
        my $hwaddr = $netdev->get("hwaddr");
        my $ipaddr = $netdev->get("ipaddr");

        &dprint("Object $nodename del netdev $devname\n");
        $self->netdevs()->del($netdev);
        if ($hwaddr) {
            $self->del("_hwaddr", $hwaddr);
        }
        if ($ipaddr) {
            $self->del("_ipaddr", $ipaddr);
        }
    } else {
        &eprint("Object $nodename has no netdev \"$devname\" configured!\n");
    }
    return $netdev;
}


=item hwaddr_list()

Shortcut to retrieve a list of all HWADDR's for this node

=cut

sub
hwaddr_list()
{
    my $self = shift;

    return $self->get("_hwaddr");
}


=item hwaddr($devname, [ $value ])

Get or set the hwaddr for the network device named I<$devname>.

=cut

sub
hwaddr()
{
    my ($self, $devname, $new_hwaddr) = @_;

    return $self->update_netdev_member($devname, "hwaddr", "_hwaddr", lc($new_hwaddr),
                                       qr/^((?:[0-9a-f]{2}:){5,7}[0-9a-f]{2})$/);
}


=item ipaddr_list()

Shortcut to retrieve a list of all IP addresses for this node

=cut

sub
ipaddr_list()
{
    my $self = shift;

    return $self->get("_ipaddr");
}


=item ipaddr($devname, [ $value ])

Get or set the ipaddr for the network device named I<$devname>.

=cut

sub
ipaddr()
{
    my ($self, $devname, $new_ipaddr) = @_;

    return $self->update_netdev_member($devname, "ipaddr", "_ipaddr", $new_ipaddr,
                                       qr/^(\d+\.\d+\.\d+\.\d+)$/);
}


=item netmask($devname, [ $value ])

Get or set the netmask for the network device named I<$devname>.

=cut

sub
netmask()
{
    my ($self, $devname, $new_netmask) = @_;

    return $self->update_netdev_member($devname, "netmask", "", $new_netmask,
                                       qr/^(\d+\.\d+\.\d+\.\d+)$/);
}


=item network($devname, [ $value ])

Get or set the network for the network device named I<$devname>.

=cut

sub
network()
{
    my ($self, $devname, $new_network) = @_;

    return $self->update_netdev_member($devname, "network", "", $new_network,
                                       qr/^(\d+\.\d+\.\d+\.\d+)$/);
}


=item gateway($devname, [ $value ])

Get or set the gateway for the network device named I<$devname>.

=cut

sub
gateway()
{
    my ($self, $devname, $new_gateway) = @_;

    return $self->update_netdev_member($devname, "gateway", "", $new_gateway,
                                       qr/^(\d+\.\d+\.\d+\.\d+)$/);
}


=item fqdn($devname, [ $value ])

Get or set the FQDN for the network device named I<$devname>.

=cut

sub
fqdn()
{
    my ($self, $devname, $new_fqdn) = @_;

    return $self->update_netdev_member($devname, "fqdn", "", $new_fqdn,
                                       qr/^([a-zA-Z0-9\-\.\_]+)$/);
}


=item mtu($devname, [ $value ])

Get or set the MTU for the network device named I<$devname>.

=cut

sub
mtu()
{
    my ($self, $devname, $new_mtu) = @_;

    return $self->update_netdev_member($devname, "mtu", "", $new_mtu,
                                       qr/^([0-9]+)$/);
}


=back

=head1 SEE ALSO

Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

# Validate a network device name.
sub
validate_netdev_name()
{
    my ($devname) = @_;

    if ($devname && ($devname =~ /^(\w+)$/)) {
        return lc($1);
    } else {
        &eprint("Invalid network device name \"$devname\"\n");
        return undef;
    }
}

# Update a netdev sub-object.
sub
update_netdev_member()
{
    my ($self, $devname, $member, $tracker, $new_value, $validator) = @_;
    my ($netdev, $nodename);

    $nodename = $self->nodename() || "UNDEF";
    if (! $devname) {
        my $netdevs = $self->netdevs();

        if ($netdevs->count() == 1) {
            $devname = $netdevs->get_object(0)->get("name");
        } else {
            &eprintf("Device name required; node $nodename has %d network devices.\n",
                     $netdevs->count());
            return undef;
        }
    }
    if (!($devname = &validate_netdev_name($devname))) {
        return undef;
    }

    $netdev = $self->netdev_get_add($devname);
    if ($new_value) {
        if ($new_value =~ $validator) {
            my $old_value = $netdev->get($member) || "";

            $new_value = $1;
            &dprint("Updating object $nodename.$devname.$member:  \"$old_value\" -> \"$new_value\"\n");
            $netdev->set($member, $new_value);
            if ($tracker) {
                if ($old_value) {
                    # Delete the previous member if exists...
                    $self->del($tracker, $old_value);
                }
                $self->add($tracker, $new_value);
            }
        } else {
            &eprint("Invalid value for $nodename.$devname.$member:  \"$new_value\"\n");
        }
    }
    return $netdev->get($member);
}

# This function is used internally to update the object's name member which
# is dynamically created to account for more complicated nomenclature schemes.
sub
genname()
{
    my ($self) = @_;
    my $nodename = $self->nodename();
    my $clustername = $self->cluster();
    my $domainname = $self->domain();
    my @names;

    if (!defined($nodename)) {
        my $name = $self->get("name");

        if (ref(\$name) eq "SCALAR") {
            &dprint("Object nodename not defined, converting...\n");
            $nodename = $name;
            $self->set("nodename", $nodename);
        }
    }

    if (defined($nodename)) {
        push(@names, $nodename);
        if (defined($clustername)) {
            push(@names, "$nodename.$clustername");
            if (defined($domainname)) {
                push(@names, "$nodename.$clustername.$domainname");
            }
        } elsif (defined($domainname)) {
            push(@names, "$nodename.$domainname");
        }
    }

    if (@names) {
        $self->set("name", \@names);
    }

    return;
}



1;
