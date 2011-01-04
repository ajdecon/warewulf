# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Vnfs.pm 50 2010-11-02 01:15:57Z mej $
#

package Warewulf::Vnfs;

use Warewulf::Object;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::Vnfs - Warewulf's general object instance object interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Vnfs;

    my $obj = Warewulf::Vnfs->new();


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

    return $self->init(@_);
}


=item type()

Return a string that defines this object type as it will be stored in the
datastore.

=cut
sub
type($)
{
    my $self = shift;

    return("vnfs");
}


sub
lookups($)
{
    my $self = shift;

    return(qw(name id));
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
