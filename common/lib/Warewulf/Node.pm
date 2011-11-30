# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#

package Warewulf::Node;

use Warewulf::Object;
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
            my $name = $self->get("name");
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


=item netdevs()

List the configured network devices configured for this node object

=cut
sub
netdevs()
{
    my ($self) = @_;
    my @device_names;

    foreach my $ndev ($self->get("netdevs")) {
        push(@device_names, $ndev->get("name"));
    }

    return(@device_names);
}




=item netdel($device)

Delete a network device from the object

=cut
sub
netdel()
{
    my ($self, $device) = @_;
    my $netdevObject;

    if ($device) {
        my $name = $self->get("name") || "UNDEF";
        foreach my $ndev ($self->get("netdevs")) {
            if ($ndev->get("name") eq $device) {
                $netdevObject = $ndev;
            }
        }
        if ($netdevObject) {
            &dprint("Object $name del netdev $device\n");
            my $hwaddr = $netdevObject->get("hwaddr");
            $self->del("netdevs", $netdevObject);
            if ($hwaddr) {
                $self->del("_hwaddr", $hwaddr);
            }
        } else {
            &eprint("Object $name has no netdev '$device' configured!\n");
        }
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
    my $netdevObject;

    if ($device) {
        my $name = $self->get("name") || "UNDEF";
        foreach my $ndev ($self->get("netdevs")) {
            if ($ndev->get("name") eq $device) {
                $netdevObject = $ndev;
            }
        }
        if ($string) {
            if (! $netdevObject) {
                &dprint("Creating new netdev object for $name.$device\n");
                $netdevObject = Warewulf::Object->new();
                $netdevObject->set("name", $device);
                $self->add("netdevs", $netdevObject);
            }
            if ($string =~ /^((?:[0-9a-f]{2}:){5}[0-9a-f]{2})$/) {
                &dprint("Setting object $name: $device.$key = $1\n");
                $netdevObject->set($key, $1);
                $self->add("_hwaddr", $1);
            } else {
                &eprint("Invalid characters to set $key = '$string'\n");
            }
        }
        if ($netdevObject) {
            return($netdevObject->get($key));
        }
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

    if ($device) {
        my $name = $self->get("name") || "UNDEF";
        foreach my $ndev ($self->get("netdevs")) {
            if ($ndev->get("name") eq $device) {
                $netdevObject = $ndev;
            }
        }
        if ($string) {
            if (! $netdevObject) {
                &dprint("Creating new netdev object for $name.$device\n");
                $netdevObject = Warewulf::Object->new();
                $netdevObject->set("name", $device);
                $self->add("netdevs", $netdevObject);
            }
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

    if ($device) {
        my $name = $self->get("name") || "UNDEF";
        foreach my $ndev ($self->get("netdevs")) {
            if ($ndev->get("name") eq $device) {
                $netdevObject = $ndev;
            }
        }
        if ($string) {
            if (! $netdevObject) {
                &dprint("Creating new netdev object for $name.$device\n");
                $netdevObject = Warewulf::Object->new();
                $netdevObject->set("name", $device);
                $self->add("netdevs", $netdevObject);
            }
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

    if ($device) {
        my $name = $self->get("name") || "UNDEF";
        foreach my $ndev ($self->get("netdevs")) {
            if ($ndev->get("name") eq $device) {
                $netdevObject = $ndev;
            }
        }
        if ($string) {
            if (! $netdevObject) {
                &dprint("Creating new netdev object for $name.$device\n");
                $netdevObject = Warewulf::Object->new();
                $netdevObject->set("name", $device);
                $self->add("netdevs", $netdevObject);
            }
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
