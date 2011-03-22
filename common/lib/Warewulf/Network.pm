# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Network.pm 191 2011-01-17 23:27:51Z gmk $
#

package Warewulf::Network;

use Warewulf::Logger;
use Warewulf::Object;
use File::Basename;
use Socket;
require 'sys/ioctl.ph';

our @ISA = ('Warewulf::Object');


=head1 NAME

Warewulf::Network- Various helper functions

=head1 ABOUT

The Warewulf::Network provides some additional helper functions

=head1 SYNOPSIS

    use Warewulf::Network;

=cut


=item new()

Instantiate an object.  Any initializer accepted by the C<set()>
method may also be passed to C<new()>.

=cut

sub
new($)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless($self, $class);

    return $self->init(@_);
}

sub
init()
{
    my ($self)  = @_;

    return($self);
}


=item ipaddr($device);

Return the IPv4 address of the given device name

=cut
sub ipaddr()
{
    my ($self, $device) = @_;

    if ($device) {
        if ($device =~ /^([a-zA-Z0-9\:\.]+)$/) {
            my $device_clean = $1;
            my $socket;
            socket($socket, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]) || die "unable to create a socket: $!\n";
            my $buf = pack('a256', $device_clean);
            if (ioctl($socket, SIOCGIFADDR(), $buf) && (my @address = unpack('x20 C4', $buf))) {
                return join('.', @address);
            }
        } else {
            &dprint("Illegal characters used in network device name\n");
        }
    } else {
        &wprint("Called ipaddr() on device object without a device name\n");
    }
    return();
}


=item netmask($device)

Return the IPv4 netmask of the given device name

=cut
sub netmask()
{
    my ($self, $device) = @_;

    if ($device) {
        if ($device =~ /^([a-zA-Z0-9\:\.]+)$/) {
            my $device_clean = $1;
            my $socket;
            socket($socket, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]) || die "unable to create a socket: $!\n";
            my $buf = pack('a256', $device_clean);
            if (ioctl($socket, SIOCGIFNETMASK(), $buf) && (my @address = unpack('x20 C4', $buf))) {
                return join('.', @address);
            }
        } else {
            &dprint("Illegal characters used in network device name\n");
        }
    } else {
        &wprint("Called netmask() on device object without a device name\n");
    }

    return();
}


=item network($device)

Return the IPv4 network of the given device name

=cut
sub network {
    my ($self, $device) = @_;
    my $ipaddr = $self->ipaddr($device);
    my $netmask = $self->netmask($device);

    if ($ipaddr and $netmask) {
        my $net_bin = unpack("N", inet_aton($ipaddr));
        my $mask_bin = unpack("N", inet_aton($netmask));
        my $net = ( $net_bin & $mask_bin ) | ( 0 & ~$mask_bin );

        return(inet_ntoa(pack('N',$net)));
    }

    return();
}



=item list_devices()

Return a list of all supported network devices

=cut
sub list_devices()
{
    my ($self) = @_;
    my @ret;

    foreach my $devpath (glob("/sys/class/net/*")) {
        push(@ret, basename($devpath));
    }

    return(@ret);
}



=item list_ipaddrs()

Return a list of all supported network devices and their configured IP addresses

=cut
sub list_ipaddrs()
{
    my ($self) = @_;
    my @ret;

    foreach my $dev ($self->list_devices()) {
        if (my $ipaddr = $self->ipaddr($dev)) {
            push(@ret, $ipaddr);
        }
    }

    return(@ret);
}


=item ip_serialize($ipaddress)

Convert a given IPv4 address to a serial numeric integer.

=cut
sub
ip_serialize()
{
    my ($self, $string) = @_;

    if ($string =~ /^\d+\.\d+\.\d+\.\d+$/) {
        return(unpack("N", inet_aton($string)));
    } elsif ($string =~ /^\d+$/) {
        return($string)
    }

    return();
}


=item ip_unserialize($integer)

Convert a given serialized numeric integer into a properly formatted IPv4 address.

=cut
sub
ip_unserialize()
{
    my ($self, $string) = @_;

    if ( $string =~ /^\d+$/ ) {
        return(inet_ntoa(pack('N', $string)));
    } elsif ($string =~ /^\d+\.\d+\.\d+\.\d+$/) {
        return($string);
    }

    return();
}

=head1 SEE ALSO

Warewulf

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

1;
