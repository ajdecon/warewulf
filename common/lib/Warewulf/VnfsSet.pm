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
# $Id: VnfsSet.pm 50 2010-11-02 01:15:57Z mej $
#

package Warewulf::VnfsSet;

use Warewulf::Include;
use Warewulf::ObjectSet;

our @ISA = ('Warewulf::ObjectSet');

=head1 NAME

Warewulf::VnfsSet - Warewulf's general object instance object interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::VnfsSet;

    my $obj = Warewulf::VnfsSet->new();


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
    return $self;
}







=back

=head1 SEE ALSO

Warewulf::Vnfs, Warewulf::ObjectSet

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
