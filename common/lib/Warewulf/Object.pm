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

our @ISA = ();

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
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = ();
    my $hashref = shift;

    $self = {};

    bless($self, $class);

    if ($hashref) {
        $self->add_hash($hashref);
    }

    return $self;
}


=item get(key)

Return the value of the key defined.

=cut
sub
get($)
{
    my $self = shift;
    my $key = shift;

    if (exists($self->{"DATA"}{$key})) {
        return $self->{"DATA"}{$key};
    } else {
        return;
    }
}


=item set(key,value)

Set a key/value pair.

=cut
sub
set($$)
{
    my $self = shift;
    my $key = shift;
    my $value = shift;

    return ($self->{"DATA"}{$key} = $value);
}


=item add_hash($hash_obj)

Add a hash object to this object

=cut
sub
add_hash($$)
{
    my $self = shift;
    my $ref = shift;

    if (ref($ref) eq "HASH") {
        %{$self->{"DATA"}} = %{$ref}
    } elsif (ref($ref) eq "ARRAY") {
        %{$self->{"DATA"}} = %{$ref}->[0];
    }
}


=item get_hash()

Return a reference to a hash object representing all of the fields of this object

=cut
sub
get_hash($)
{
    my $self = shift;
    my $hashref;

    %{$hashref} = %{$self->{"DATA"}};

    return($hashref);
}


=item *([value])

Any methods will be automatically translated into a get/set command, so
you can do things like this:

   $store->anything_you_wish_to_use->("the value should be here");
   my $value = $store->anything_you_wish_to_use();

=cut
sub
AUTOLOAD
{
    my $self = shift;
    my $type = ref($self) || return undef;
    my $key = $AUTOLOAD;
    my $value = shift;

    if ($key =~ /destroy/i) {
        return;
    }
    $key =~ s/.*://;

    if ($value) {
        $self->set($key, $value);
    }

    return $self->get($key);
}


=back

=head1 SEE ALSO

Warewulf:ObjectSet:

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
