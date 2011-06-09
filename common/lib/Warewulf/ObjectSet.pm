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
    my $self = {};
    my $arrayref = shift;

    $self = $class->SUPER::new();
    bless($self, $class);

    if ($arrayref) {
        $self->add_hashes($arrayref);
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


=item get_object($index)

Return the single Object at the given array index

=cut
sub
get_object($)
{
    my $self = shift;
    my $index = shift;

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
    my $self = shift;
    my $key = shift;
    my @ret;

    foreach my $obj ( sort {$a->get("name") cmp $b->get("name")} @{$self->{"ARRAY"}}) {
        if (my $value = $obj->get($key)) {
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
    my $self = shift;

    if (exists($self->{"ARRAY"})) {
        return (sort {$a->get("name") cmp $b->get("name")} @{$self->{"ARRAY"}});
    } else {
        return;
    }
}

=item count()

Return the number of entities in the ObjectSet

=cut
sub
count()
{
    my $self = shift;
    my $count;

    &dprint("Counting objects in set\n");
    if (exists($self->{"ARRAY"})) {
        $count = scalar @{$self->{"ARRAY"}} || 0;
    } else {
        $count = 0;
    }
    &dprint("Found '$count' objects in Set\n");

    return($count);
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
    
    if (exists($self->{"INDEXES"})) {
        return (@{$self->{"INDEXES"}});
    } else {
        return;
    }
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


=head1 SEE ALSO

Warewulf::Object, Warewulf::DSOFactory

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
