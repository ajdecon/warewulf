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

#use Warewulf::Debug;
use Warewulf::Logger;

use Exporter;
use File::Basename;
use Socket;
require 'sys/ioctl.ph';

our @ISA = ('Exporter');

our @EXPORT = (
    '&get_interfaces',
    '&get_interface_address',
    '&get_interface_netmask',
    '&ip_serialize',
    '&ip_unserialize',
);

=head1 NAME

Warewulf::Network- Various helper functions

=head1 ABOUT

The Warewulf::Network provides some additional helper functions

=head1 SYNOPSIS

    use Warewulf::Network;

=cut


=item get_interfaces()

Return a list of all found network interfaces for this host

=cut
sub get_interfaces()
{
    my @ret;

    foreach my $devpath (glob("/sys/class/net/*")) {
        push(@ret, basename($devpath));
    }

    return(@ret);
}


=item get_interface_address($device)

Return the IPv4 address of the given device

=cut
sub get_interface_address()
{
    my $device = shift;
    my $socket;
    socket($socket, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]) || die "unable to create a socket: $!\n";
    my $buf = pack('a256', $device);
    if (ioctl($socket, SIOCGIFADDR(), $buf) && (my @address = unpack('x20 C4', $buf))) {
        return join('.', @address);
    }
    return();
}


=item get_interface_netmask($device)

Return the IPv4 netmask of the given device

=cut
sub get_interface_netmask()
{
    my $device = shift;
    my $socket;
    socket($socket, PF_INET, SOCK_STREAM, (getprotobyname('tcp'))[2]) || die "unable to create a socket: $!\n";
    my $buf = pack('a256', $device);
    if (ioctl($socket, SIOCGIFNETMASK(), $buf) && (my @address = unpack('x20 C4', $buf))) {
        return join('.', @address);
    }
    return();
}


=item ip_serialize($ipaddress)

Convert a given IPv4 address to a serial numeric integer.

=cut
sub
ip_serialize($)
{
    my $ip = shift();

    if ( $ip =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
        return(unpack("N", inet_aton($ip)));
    }

    return();
}


=item ip_unserialize($integer)

Convert a given serialized numeric integer into a properly formatted IPv4 address.

=cut
sub
ip_unserialize($)
{
    my $int = shift();

    if ( $bin =~ /^\d+$/ ) {
        return(inet_ntoa(pack('N',$int)));
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
