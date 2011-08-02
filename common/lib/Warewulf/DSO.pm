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

=head1 SYNOPSIS

    our @ISA = ('Warewulf::DSO');

=head1 DESCRIPTION

Objects which are to be persisted to (and subsequently pulled from)
the Warewulf Data Store should inherit from the Warewulf::DSO parent
class.  This class should never be directly instantiated.

=head1 METHODS

=over 4

=item new()

The new method is the constructor for this object.  It will create an
object instance and return it to the caller.

NOTE:  This method should only ever be called as SUPER::new() by a
derived class; there should never be a direct instance of this class.

=cut

sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

#    $self = $class->SUPER::new();
    bless($self, $class);

    return $self->init(@_);
}

=item type()

Returns a string that defines this object type as it will be stored in
the datastore.

=cut

sub
type($)
{
    my $self = shift;
    my $type = ref($self);
    $type =~ s/^.+:://;

    if ($type eq "DSO") {
        if (my $given_type = $self->get("type")) {
            return lc($given_type);
        } else {
            return "unknown";
        }
    }
    return lc($type);
}

=item lookups()

Return a list of lookup names for this DSO type.

=cut

sub
lookups($)
{
    my $self = shift;

    return ("_ID", "NAME");
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
