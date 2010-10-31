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

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = ();

=head1 NAME

Warewulf::ObjectSet - Warewulf's object set object interface.

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

    %{$self} = ();

    bless($self, $class);

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
        push(@{$self->{"ARRAY"}}, $obj);
        push(@index, $self->index(), $obj->index());
        foreach my $key (keys %{{map ({ $_ => 1 } @index)}}) {
            if(my $value = $obj->get($key)) {
                push(@{$self->{"DATA"}{"$value"}}, $obj);
            }
        }
    }

    return();
}


=item find($string)

Return the relevant object(s) by searching for the given indexed key criteria.
This for this to work, the object set or the objects themselves would have to
have defined an index field. Caution, due to how the indexing is done (hash
references), this method will not return objects in the same order as they
were added!

The return value will be either a list or a scalar depending on how you
request the data.

=cut
sub
find($$)
{
    my $self = shift;
    my $val = shift;
    my @return;

    if (exists($self->{"DATA"}{"$val"})) {
        push(@return, @{$self->{"DATA"}{"$val"}});
    }

    if (@return) {
        return(wantarray ? @return : $return[0]);
    } else {
        return();
    }
}



=item iterate()

Return an array of all node objects in this ObjectSet.

=cut
sub
iterate($)
{
    my $self = shift;

    return(@{$self->{"ARRAY"}});
}


=item index(key name)

Define which keys should be index when/if adding to an ObjectSet archive. This
allows a fast return from the ObjectSet interface.

If no key name is given, this will return the list of indexes itself.

=cut
sub
index($$)
{
    my $self = shift;
    my $key = shift;

    if ($key) {
        push(@{$self->{"INDEXES"}}, $key);
    } else {
        return(@{$self->{"INDEXES"}});
    }

    return();
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
        my $obj = Warewulf::Object->new();
        $obj->add_hash($h);
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
