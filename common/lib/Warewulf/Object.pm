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

package Warewulf::Object;

use Warewulf::Include;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = ();

=head1 NAME

Warewulf::Object - Warewulf's general object instance object interface.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Object;

    my $obj = Warewulf::Object->new();


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
    my $proto               = shift;
    my $class               = ref($proto) || $proto;
    my $self                = ();

    %{$self} = ();

    bless($self, $class);

    return($self);
}


=item get(key)

Return the value of the key defined.

=cut
sub
get($)
{
    my $self                = shift;
    my $key                 = shift;

    return($self->{"DATA"}{"$key"});
}


=item set(key,value)

Set a key/value pair.

=cut
sub
set($$)
{
    my $self                = shift;
    my $key                 = shift;
    my $value               = shift;

    $self->{"DATA"}{"$key"} = $value;

    return($value);
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


=item add_hash($hash_obj)

Add a hash object to this object

=cut
sub
add_hash($$)
{
    my $self = shift;
    my $hash_obj = shift;

    @{$self->{"DATA"}}{keys %{$hash_obj}} = values %{$hash_obj};

}


=item *([value])

Any methods will be automatically translated into a get/set command, so
you can do things like this:

   $store->anything_you_wish_to_use->("the value should be here");
   my $value = $store->anything_you_wish_to_use();

=cut
sub
AUTOLOAD($)
{
    my $self                = shift;
    my $key                 = $AUTOLOAD;
    my $value               = shift;

    if ($value) {
        $self->set($key, $value);
    }

    return($self->get($key));
}


=back

=head1 SEE ALSO

Warewulf:ObjectSet:

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
