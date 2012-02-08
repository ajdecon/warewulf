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

Warewulf::Node - Warewulf's general object instance object interface.

=head1 ABOUT

This is the primary Warewulf interface for getting and setting the base
configuration of node objects.

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

    $self = $class->SUPER::new();
    bless($self, $class);

    return $self->init(@_);
}


=item id()

Return the Database ID for this object.

=cut

sub
id()
{
    my ($self) = @_;

    return($self->get("_id") || "UNDEF");
}



=item name($string)

Set or return the name of this object. The string "UNDEF" will delete this
key from the object.

=cut

sub
name()
{
    my ($self, $string) = @_;
    my $key = "name";

    if ($string) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^([a-zA-Z0-9_\.\-]+)$/) {
            my $name = $self->get("name") || "UNDEF";
            &dprint("Object $name set $key = '$1'\n");
            $self->set($key, $1);
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    return($self->get($key) || "UNDEF");
}


=item cluster($string)

Set or return the cluster of this object. The string "UNDEF" will delete this
key from the object.

=cut

sub
cluster()
{
    my ($self, $string) = @_;
    my $key = "cluster";

    if ($string) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^([a-zA-Z0-9_\.\-]+)$/) {
            my $name = $self->get("name");
            &dprint("Object $name set $key = '$1'\n");
            $self->set($key, $1);
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    return($self->get($key) || "UNDEF");
}


=item domain($string)

Set or return the domain of this object. The string "UNDEF" will delete this
key from the object.

=cut

sub
domain()
{
    my ($self, $string) = @_;
    my $key = "domain";

    if ($string) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
        } elsif ($string =~ /^([a-zA-Z0-9_\.\-]+)$/) {
            my $name = $self->get("name");
            &dprint("Object $name set $key = '$1'\n");
            $self->set($key, $1);
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    return($self->get($key) || "UNDEF");
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

    return($self->get($key));
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

    return($self->get($key));
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


=item netdevs($match)

List the configured network devices configured for this node object. If a
match string is given, it will return just that device name.

=cut

sub
netdevs()
{
    my ($self, $match) = @_;
    my @device_names;

    if ($self->get("netdevs")) {
        &dprint("Legacy netdev format exists...\n");
        foreach my $ndev ($self->get("netdevs")) {
            if (! $match or $match eq $ndev->get("name")) {
                push(@device_names, $ndev->get("name"));
            }
        }
    }
    if ($self->get("_netdevset")) {
        foreach my $name ($self->get("_netdevset")->get_list_entries("name")) {
            if (! $match or $match eq $name) {
                push(@device_names, $name);
            }
        }
    }

    return(@device_names);
}


=item get_netobj($name)

Find or create the netdev object for this node of a given device name.

=cut

sub
get_netobj()
{
    my ($self, $name) = @_;
    my $netObj;

    if (! $self->get("_netdevset")) {
        &dprint("Creating new netdev ObjectSet\n");
        $self->set("_netdevset", Warewulf::ObjectSet->new());
    }

    if ($self->get("netdevs")) {
        &iprint("Converting legacy netdev entry(s) for node: $name\n");
        my $name = $self->name();
        foreach my $ndev ($self->get("netdevs")) {
            bless($ndev, "Warewulf::Object");
            $self->get("_netdevset")->add($ndev);
        }
        $self->get("_netdevset")->add($NetDevSet);
        $self->del("netdevs");
    }

    &dprint("Searching for device $name in the netdev set\n");
    $netObj = $self->get("_netdevset")->find("name", $name);

    if (! $netObj) {
        &dprint("Creating new netdev object for '$name'\n");
        my $netDevSet = $self->get("_netdevset");
        $netObj = Warewulf::Object->new();
        $netObj->set("name", $name);
        $netDevSet->add($netObj);
        $self->get("_netdevset")->add($NetDevSet);
    }

    return $netObj;
}


=item netdel($device)

Delete a network device from the object

=cut

sub
netdel()
{
    my ($self, $device) = @_;

    if (! $self->get("_netdevset")) {
        &dprint("Called netdel() on non-existant netdev ObjectSet!\n");
        return();
    }

    if ($device and $device =~ /^([a-z]+\d*)$/) {
        my $netdevObject = $self->get("_netdevset")->find("name", $1);
        my $name = $self->get("name") || "UNDEF";

        if ($netdevObject) {
            &dprint("Object $name del netdev $device\n");
            my $hwaddr = $netdevObject->get("hwaddr");
            $self->get("_netdevset")->del($netdevObject);
            if ($hwaddr) {
                $self->del("_hwaddr", $hwaddr);
            }
        } else {
            &eprint("Object $name has no netdev '$device' configured!\n");
        }
    } else {
        &eprint("Bad device name: $device\n");
    }

    return();
}


=item hwaddr($device, $value)

Set or return the hwaddr for a given device

=cut

sub
hwaddr()
{
    my ($self, $device, $string) = @_;
    my $key = "hwaddr";

    if ($device and $device =~ /^([a-z]+\d*)$/) {
        my $netdevObject = $self->get_netobj($1);
        my $name = $self->get("name") || "UNDEF";
        if ($string) {
            if ($string =~ /^((?:[0-9a-f]{2}:){5}[0-9a-f]{2})$/) {
                if ($netdevObject->get($key)) {
                    # Delete the previous hwaddr if exists...
                    $self->del("_hwaddr", $netdevObject->get($key));
                }
                &dprint("Setting object $name: $device.$key = $1\n");
                $netdevObject->set($key, $1);
                $self->add("_hwaddr", $1);
            } else {
                &eprint("Invalid characters to set $key = '$string'\n");
            }
        }
        &dprint("Returning netdevObject->get($key)\n");
        return($netdevObject->get($key));
    } else {
        &eprint("Bad device name!\n");
    }

    return();
}


=item ipaddr($device, $value)

Set or return the ipaddr for a given device

=cut

sub
ipaddr()
{
    my ($self, $device, $string) = @_;
    my $key = "ipaddr";
    my $netdevObject;

    if ($device and $device =~ /^([a-z]+\d*)$/) {
        my $netdevObject = $self->get_netobj($1);
        my $name = $self->get("name") || "UNDEF";
        if ($string) {
            if ($string =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                if ($netdevObject->get($key)) {
                    # Delete the previous hwaddr if exists...
                    $self->del("_hwaddr", $netdevObject->get($key));
                }
                &dprint("Setting object $name: $device.$key = $1\n");
                $netdevObject->set($key, $1);
                $self->add("_ipaddr", $1);
            } else {
                &eprint("Invalid characters to set $key = '$string'\n");
            }
        }
        if ($netdevObject) {
            return($netdevObject->get($key));
        }
    } else {
        &eprint("Bad device name!\n");
    }

    return();
}


=item netmask($device, $value)

Set or return the netmask for a given device

=cut

sub
netmask()
{
    my ($self, $device, $string) = @_;
    my $key = "netmask";
    my $netdevObject;

    if ($device and $device =~ /^([a-z]+\d*)$/) {
        my $netdevObject = $self->get_netobj($1);
        my $name = $self->get("name") || "UNDEF";
        if ($string) {
            if ($string =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
                &dprint("Setting object $name: $device.$key = $1\n");
                $netdevObject->set($key, $1);
            } else {
                &eprint("Invalid characters to set $key = '$string'\n");
            }
        }
        if ($netdevObject) {
            return($netdevObject->get($key));
        }
    } else {
        &eprint("Bad device name!\n");
    }

    return();
}


=item fqdn($device, $value)

Set or return the FQDN for a given device

=cut

sub
fqdn()
{
    my ($self, $device, $string) = @_;
    my $key = "fqdn";
    my $netdevObject;

    if ($device and $device =~ /^([a-z]+\d*)$/) {
        my $netdevObject = $self->get_netobj($1);
        my $name = $self->get("name") || "UNDEF";
        if ($string) {
            if ($string =~ /^([a-zA-Z0-9\-\.\_]+)$/) {
                &dprint("Setting object $name: $device.$key = $1\n");
                $netdevObject->set($key, lc($1));
            } else {
                &eprint("Invalid characters to set $key = '$string'\n");
            }
        }
        if ($netdevObject) {
            return($netdevObject->get($key));
        }
    } else {
        &eprint("Bad device name!\n");
    }

    return();
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


1;
