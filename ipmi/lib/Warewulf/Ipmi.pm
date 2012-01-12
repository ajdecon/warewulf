# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Node.pm 689 2011-12-20 00:34:04Z mej $
#

package Warewulf::Ipmi;

use Warewulf::Object;
use Warewulf::Node;
use Warewulf::Network;
use Warewulf::Logger;

our @ISA = ('Warewulf::Object');

push(@Warewulf::Node::ISA, 'Warewulf::Ipmi');

=head1 NAME

Warewulf::Ipmi - IPMI extentions to the Warewulf::Node object type.

=head1 ABOUT

Warewulf object types that need to be persisted via the DataStore need to have
various extentions so they can be persisted. This module enhances the object
capabilities.

=head1 SYNOPSIS

    use Warewulf::Node;
    use Warewulf::DSO::Node;

    my $obj = Warewulf::Node->new();

    $obj->ipmi_ipaddr("10.1.1.1");
    my $address = $obj->ipmi_addr();


=head1 METHODS

=over 12

=cut

=item ipmi_ipaddr($string)

Set or return the IPMI IPv4 address of this object.

=cut

sub
ipmi_ipaddr()
{
    my ($self, $string) = @_;
    my $key = "ipmi_ipaddr";
    my $ret;

    if ($string) {
        if (uc($string) eq "UNDEF") {
            my $name = $self->get("name");
            &dprint("Object $name delete $key\n");
            $self->del($key);
            $self->del("ipmi_provision");
        } elsif ($string =~ /^((\d{3}\.){3}\d+)$/) {
            my $name = $self->get("name");
            my $serialized = &ip_serialize($1);
            if ($serialized) {
                &dprint("Object $name set $key = '$serialized'\n");
                $self->set($key, $serialized);
            } else {
                &eprint("Could not properly serialize IP address: $string\n");
            }
        } else {
            &eprint("Invalid characters to set $key = '$string'\n");
        }
    }

    $ret = $self->get($key);

    if ($ret) {
        my $unserialized = &ip_unserialize($ret);
        if ($unserialized) {
            $ret = $unserialized;
        } else {
            &eprint("Could not unserialize IP data: $ret\n");
        }
    }

    return($ret);
}


=item ipmi_netmask($string)

Set or return the IPMI IPv4 netmask of this object.

=cut

sub
ipmi_netmask()
{
    my ($self, $value) = @_; 

    if ($value eq "UNDEF") {
        $value = undef;
        $self->del("ipmi_provision");
    }   
    return $self->prop("ipmi_netmask", \$value, qr/^((\d{3}\.){3}\d+)$/);
}


=item ipmi_username($string)

Set or return the IPMI username of this object.

=cut

sub
ipmi_username()
{
    my ($self, $value) = @_; 

    if ($value eq "UNDEF") {
        $value = undef;
        $self->del("ipmi_provision");
    }   
    return $self->prop("ipmi_username", \$value, qr/^([a-z0-9]+)$/);
}


=item ipmi_proto($string)

Set or return the IPMI interface protocol of this object. Supported protocols
are:

      lan (default)
      lanplus
      open
      free
      imb
      bmc
      lipmi

=cut

sub
ipmi_proto()
{
    my ($self, $value) = @_; 

    if ($value eq "lan" or
            $value eq "lanplus" or
            $value eq "open" or
            $value eq "free" or
            $value eq "ibm" or
            $value eq "bmc" or
            $value eq "lipmi") {
        $self->set("ipmi_proto", $value);
    }

    return($self->get("ipmi_proto") || "lan");
}


=item ipmi_password($string)

Set or return the IPMI password of this object.

=cut

sub
ipmi_password()
{
    my ($self, $value) = @_; 

    if ($value eq "UNDEF") {
        $value = undef;
        $self->del("ipmi_provision");
    }   
    return $self->prop("ipmi_password", \$value, qr/^([a-zA-Z0-9_]+)$/);

}


=item ipmi_provision($bool)

Automatically configure the node's IPMI interface for network access
during provision time. This will require the following IPMI paramaters to
be set:

    ipmi_ipaddr
    ipmi_netmask
    ipmi_username
    ipmi_password

note: This will take a boolean true (!=0) or false (0).

=cut

sub
ipmi_provision()
{
    my ($self, $value) = @_; 
    my $key = "ipmi_provision";

    if ($value) {
        if ($value eq "0") {
            $self->del($key);
        } else {
            if ($self->ipmi_ipaddr() and $self->ipmi_netmask() and $self->ipmi_username() and $self->ipmi_password()) {
                $self->set($key, "1");
            } else {
                &eprint("Could not set ipmi_provision() because requirements not met\n");
            }
        }
    }
    return $self->get($key);
}


=item ipmi_command($action)

Return the IPMI shell command for a given action as follows:

    poweron     Turn the node on
    poweroff    Turn the node off
    powercycle  Cycle the power on the node
    powerstatus Check power status

=cut

sub
ipmi_command()
{
    my ($self, $action) = @_;
    my $ipaddr = $self->ipmi_ipaddr();
    my $username = $self->ipmi_username();
    my $password = $self->ipmi_password();
    my $proto = $self->ipmi_proto();
    my $ret = "ipmitool ";

    print "->$username<-\n";

    if ($ipaddr and $username and $password and $proto) {
        $ret .= "-I $proto -U $username -P $password -H $ipaddr ";
        if ($action eq "poweron") {
            $ret .= "chassis power on";
        } elsif ( $action eq "poweroff") {
            $ret .= "chassis power off";
        } elsif ( $action eq "powercycle") {
            $ret .= "chassis power cycle";
        } elsif ( $action eq "powerstatus") {
            $ret .= "chassis power status";
        } else {
            &eprint("Unsupported IPMI action: $action\n");
        }
    } else {
        &eprint("Could not build command for $name, unconfigured requirement(s)\n");
    }

    return($ret);
}



&set_log_level("DEBUG");

my $o = Warewulf::Node->new();

# GMK/MEJ: Object::Prop() deletes key if value reference is empty.

$o->name("moo");
$o->ipmi_ipaddr("10.1.1.1");
$o->ipmi_username("rootme");
$o->ipmi_password("pass1234");

my $cmd = $o->ipmi_command("poweron");

print "->$cmd<-\n\n";

=back

=head1 SEE ALSO

Warewulf::DSO, Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
