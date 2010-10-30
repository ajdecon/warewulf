# Copyright (c) 2003-2010, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# The GNU GPL Document can be found at:
# http://www.gnu.org/copyleft/gpl.html
#
# $Id$
#

package Warewulf::NodeSet;

use Warewulf::Include;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = ();

=head1 NAME

Warewulf::NodeSet - Warewulf's node set object interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::NodeSet;

    my $obj = Warewulf::NodeSet->new();


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

    %{$self} = ();

    bless($self, $class);

    return($self);
}

=item add($nodeobj)

The add method will add a node object into the nodeset object.

=cut
sub
add($$)
{
    my $self = shift;
    my $nodeobj = shift;

    if (defined($nodeobj)) {
        my $hostname = $nodeobj->hostname();
        my $ipaddr = $nodeobj->ipaddr();
        my $hwaddr = $nodeobj->hwaddr();
        my $id = $nodeobj->id();
        if ($id) {
            push(@{$self->{"BY_ID"}{"$id"}}, $nodeobj);
        }
        if ($hostname) {
            push(@{$self->{"BY_HOSTNAME"}{"$hostname"}}, $nodeobj);
        }
        if ($ipaddr) {
            push(@{$self->{"BY_IPADDR"}{"$ipaddr"}}, $nodeobj);
        }
        if ($hwaddr) {
            push(@{$self->{"BY_HWADDR"}{"$hwaddr"}}, $nodeobj);
        }
    }

    return();
}


=item get($searchby)

Return the relevant node object(s) by searching for the given searchby
criteria. Valid search credentials are hostname, IP address, and HW
address if these were stored in the original object ***WHEN THE OBJECT
WAS INITIALLY ADDED TO THIS NODESET***.

The return value will be either a list or a scalar depending on how you
request the data.

=cut
sub
get($$)
{
    my $self = shift;
    my $val = shift;
    my @return;

    if (exists($self->{"BY_HOSTNAME"}{"$val"})) {
        push(@return, @{$self->{"BY_HOSTNAME"}{"$val"}});
    } elsif (exists($self->{"BY_ID"}{"$val"})) {
        push(@return, @{$self->{"BY_ID"}{"$val"}});
    } elsif (exists($self->{"BY_IPADDR"}{"$val"})) {
        push(@return, @{$self->{"BY_IPADDR"}{"$val"}});
    } elsif (exists($self->{"BY_HWADDR"}{"$val"})) {
        push(@return, @{$self->{"BY_HWADDR"}{"$val"}});
    }

    if (@return) {
        return(wantarray ? @return : $return[0]);
    } else {
        return();
    }
}



=item iterate()

Return an array of all node objects in this NodeSet.

=cut
sub
iterate($)
{
    my $self = shift;
    my @return;

    foreach my $obj_array (keys %{$self->{"BY_ID"}}) {
        push(@return, @{$obj_array});
    }

    if (@return) {
        return(@return);
    } else {
        return();
    }
}




=back

=head1 SEE ALSO

Warewulf::Node

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
