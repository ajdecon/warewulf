# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: ObjectFactory.pm 83 2010-12-09 22:13:21Z gmk $
#

package Warewulf::ObjectFactory;

use Warewulf::Util;
use Warewulf::Logger;
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

Warewulf::Object, Warewulf::ObjectSet

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

1;

