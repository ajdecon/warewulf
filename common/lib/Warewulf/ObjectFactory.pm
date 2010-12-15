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
# $Id: DB.pm 83 2010-12-09 22:13:21Z gmk $
#

package Warewulf::ObjectFactory;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::Config;
use Warewulf::Object::Node;
use Warewulf::Object::Vnfs;
use DBI;

=head1 NAME

Warewulf::DB - Database interface

=head1 ABOUT

The Warewulf::DB interface simplies typically used DB calls and operates on
Warewulf::Objects and Warewulf::ObjectSets for simplistically integrating
with native Warewulf code.

=head1 SYNOPSIS

    use Warewulf::ObjectFactory;

    my $obj = Warewulf::ObjectFactory->new($type);

=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto = shift;
    my $type = uc(shift);

    if ($type eq "NODE") {
        return(Warewulf::Object::Node->new(@_));
    } elsif ($type eq "VNFS") {
        return(Warewulf::Object::Vnfs->new(@_));
    } else {
        &eprint("Unknown object Type: $type\n");
        exit 1;
    }

    return();
}

=back

=head1 SEE ALSO

Warewulf::Object Warewulf::ObjectSet

=head1 COPYRIGHT

Copyright (c) 2003-2010, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

The GNU GPL Document can be found at:
http://www.gnu.org/copyleft/gpl.html

=cut




1;

