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

package Warewulf::ObjectSet;

use Warewulf::Include;
use Warewulf::Object;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::ObjectSet - Warewulf's object set interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::ObjectSet;

    my $obj = Warewulf::ObjectSet->new();


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
    my $hashref = shift;

    $self = $class->SUPER::new(@_);

    bless($self, $class);

    if ($hashref) {
        $self->add_hashes($hashref);
    }

    return($self);
}

=item add($obj)

The add method will add an object into the ObjectSet object.

=cut
sub
add($$)
{
    my $self = shift;
    my $obj = shift;
    my @index;

    if (defined($obj)) {
        # Maintain sorted list of objects in set.
        push(@{$self->{"ARRAY"}}, $obj);

        # Add object to all indexes.
        foreach my $key ($self->index()) {
            my $value = $obj->get($key);

            if (defined($value)) {
                push(@{$self->{"DATA"}{$key}{$value}}, $obj);
            }
        }
    }
}


=item find($index, $string)

Return the relevant object(s) by searching for the given indexed key
criteria.  For this to work, the object set must have index fields
defined.  Caution, due to how the indexing is done (hash references),
this method will not return objects in the same order as they were
added!

The return value will be either a list or a scalar depending on how
you request the data.

=cut
sub
find($$$)
{
    my ($self, $key, $val) = @_;
    my @return;

    if (!exists($self->{"DATA"}{$key})) {
        return undef;
    }
    if (!exists($self->{"DATA"}{$key}{$val})) {
        return ();
    }
    return ((wantarray()) ? (@{$self->{"DATA"}{$key}{$val}}) : ($self->{"DATA"}{$key}{$val}[0]));
}



=item get_list()

Return an array of all objects in this ObjectSet.

=cut
sub
get_list($)
{
    my $self = shift;

    return (@{$self->{"ARRAY"}});
}


=item index(key name)

Define which member variables should be indexed when adding to an
ObjectSet archive. This allows a fast return from the ObjectSet
interface.

Returns the current (possibly updated) list.

=cut
sub
index($$)
{
    my $self = shift;
    my $key = shift;

    if ($key && !scalar(grep($key, @{$self->{"INDEXES"}}))) {

        push(@{$self->{"INDEXES"}}, $key);

#        if (exists($self->{"DATA"})) {
            $self->{"DATA"} = ();
            # Add object to all indexes.
            foreach my $index (@{$self->{"INDEXES"}}) {
                foreach my $obj (@{$self->{"ARRAY"}}) {
                    my $value = $obj->get($index);

                    if (defined($value)) {
                        push(@{$self->{"DATA"}{$index}{$value}}, $obj);
                    }
                }
            }
#        }
    }
    return (@{$self->{"INDEXES"}});
}


=item add_hashes($array_obj)

Add an array of hashes to this object set

=cut
sub
add_hashes($$)
{
    my $self = shift;
    my $array_obj = shift;

    foreach my $h (@{$array_obj}) {
        my $obj = Warewulf::Object->new($h);
        $self->add($obj);
    }

}


=back

=head1 SEE ALSO

Warewulf::Object

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
