# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::ObjectSet;

use Warewulf::Object;
use Warewulf::Logger;
use Warewulf::DSOFactory;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::ObjectSet - Warewulf's object set interface.

=head1 SYNOPSIS

    use Warewulf::ObjectSet;

    my $obj = Warewulf::ObjectSet->new();

=head1 DESCRIPTION

An ObjectSet is a convenient, object-oriented container for holding an
arbitrary collection of Objects.  Its most common/notable use is in
the DataStore:  return values for queries to the DataStore will be in
the form of ObjectSets.

=head1 METHODS

=over 4

=item new()

Create and return a new ObjectSet instance.

=cut

sub
new($$)
{
    my ($proto, $arrayref) = @_;
    my $class = ref($proto) || $proto;
    my $self;

    $self = $class->SUPER::new();
    bless($self, $class);

    if ($arrayref) {
        $self->add_hashes($arrayref);
    }

    return $self;
}

=item add($obj)

The add method will add an object to the ObjectSet.

=cut

sub
add($$)
{
    my ($self, $obj) = @_;
    my @index;

    if (defined($obj)) {
        # Maintain ordered list of objects in set.
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

=item del($obj)
=item del($key, $value)

Deletes an item from the ObjectSet, either by direct reference ($obj)
or by the value ($value) of an indexed key ($key).  The second form is
essentially equivalent to calling find($key, $value) and invoking
del() on the resulting object(s).  Returns the removed object(s).

=cut

sub
del()
{
    my ($self, $key, $value) = @_;
    my (@objs);

    if (defined($key) && defined($value)) {
        # Find all objects in set (probably just 1) that have this key/value pair.
        @objs = $self->find($key, $value);
    } elsif (defined($key) && ref($key)) {
        if (ref($key) eq "ARRAY") {
            # Array reference to a list of objects.  Delete them all.
            @objs = @{$key};
        } else {
            # Just one object.  Delete it.
            @objs = ($key);
        }
    } else {
        # Error in parameters.
        return undef;
    }

    # In most cases, @objs will only contain a single object.  However, nothing guarantees
    # that the indexes of an ObjectSet will be unique; in fact, it's designed to handle
    # indexing on anything, even non-unique keys.  So any number of objects could match.
    foreach my $obj (@objs) {
        # Update all indexes to remove this object.
        foreach $key ($self->index()) {
            $value = $obj->get($key);
            # Remove all index entries that have $key set to this $value.
            @{$self->{"DATA"}{$key}{$value}} = grep { $_ ne $obj } @{$self->{"DATA"}{$key}{$value}};
            if (scalar(@{$self->{"DATA"}{$key}{$value}}) == 0) {
                # We just emptied that list, so remove it from the index hash.
                delete $self->{"DATA"}{$key}{$value};
            }
        }
        # Remove the object from the set.
        @{$self->{"ARRAY"}} = grep { $_ ne $obj } @{$self->{"ARRAY"}};
    }
    return ((wantarray()) ? (@objs) : ($objs[0]));
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

    if (!exists($self->{"DATA"}{$key})) {
        return undef;
    }
    if (!exists($self->{"DATA"}{$key}{$val})) {
        return ();
    }
    return ((wantarray()) ? (@{$self->{"DATA"}{$key}{$val}}) : ($self->{"DATA"}{$key}{$val}[0]));
}

=item get_object($index)

Return the single Object at the given array index

=cut

sub
get_object($)
{
    my ($self, $index) = @_;

    if (exists($self->{"ARRAY"}[$index])) {
        return ($self->{"ARRAY"}[$index]);
    } else {
        return;
    }
}

=item get_list_entries($index)

Return an array of list entries found in the current set.

=cut

sub
get_list_entries($$)
{
    my ($self, $key) = @_;
    my @ret;

    foreach my $obj (sort {$a->get("name") cmp $b->get("name")} @{$self->{"ARRAY"}}) {
        my $value = $obj->get($key);

        if ($value) {
            push(@ret, $value);
        }
    }

    if (@ret) {
        return (@ret);
    } else {
        return;
    }
}

=item get_list()

Return an array of all objects in this ObjectSet.

=cut

sub
get_list($$)
{
    my ($self) = @_;

    if (exists($self->{"ARRAY"})) {
        return (sort {$a->get("name") cmp $b->get("name")} @{$self->{"ARRAY"}});
    } else {
        return;
    }
}

=item count()

Return the number of entities in the ObjectSet.

=cut

sub
count()
{
    my ($self) = @_;
    my $count;

    &dprint("Counting objects in set\n");
    if (exists($self->{"ARRAY"})) {
        $count = scalar(@{$self->{"ARRAY"}}) || 0;
    } else {
        $count = 0;
    }
    &dprint("Found '$count' objects in Set\n");

    return $count;
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
    my ($self, $key) = @_;

    if ($key && !scalar(grep($key, @{$self->{"INDEXES"}}))) {
        push(@{$self->{"INDEXES"}}, $key);
#        if (exists($self->{"DATA"})) {
            $self->{"DATA"} = {};
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
    
    if (exists($self->{"INDEXES"})) {
        return (@{$self->{"INDEXES"}});
    } else {
        return;
    }
}

=item add_hashes($array_obj)

Add an array of hashes to this ObjectSet.

=cut

sub
add_hashes($$)
{
    my ($self, $array_obj) = @_;

    foreach my $h (@{$array_obj}) {
        my $obj;

        if (ref($h) eq "HASH") {
            if (exists($h->{"TYPE"})) {
                $obj = Warewulf::DSOFactory->new($h->{"TYPE"}, $h);
            } else {
                $obj = Warewulf::Object->new($h);
            }
            $self->add($obj);
        }
    }

}

=back

=head1 SEE ALSO

Warewulf::Object, Warewulf::DSOFactory

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
