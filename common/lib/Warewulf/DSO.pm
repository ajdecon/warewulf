# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: DSO.pm 50 2010-11-02 01:15:57Z gmk $
#

package Warewulf::DSO;

use Warewulf::Object;
use Warewulf::DataStore;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::DSO - Warewulf's DSO (Data Store Object) base class

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::DSO;

    my $obj = Warewulf::DSO->new();


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


=item type()

Return a string that defines this object type as it will be stored in the
datastore.

=cut
sub
type($)
{
    my $self = shift;
    my $type = ref($self);
    $type =~ s/^.+:://;

    return(lc($type));
}


=item lookups()

Return a list of lookup names for this DSO type.

=cut
sub
lookups($)
{
    my $self = shift;

    return("NAME");
}


=item persist()

Persist this object into the datastore

=cut
sub
persist($)
{
    my $self = shift;
    my $datastore = Warewulf::DataStore->new();

    $datastore->persist($self);
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
