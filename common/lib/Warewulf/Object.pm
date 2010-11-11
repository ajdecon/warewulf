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

Warewulf::Object - Warewulf's general object.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Object;

    my $obj = Warewulf::Object->new();


=head1 METHODS

=over 12

=item new()

Instantiate an object.

=cut

sub
new($)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless($self, $class);

    return $self->init(@_);
}

=item init(...)

Initialize an object, possibly with a hash or hashref.  All data
currently stored in the object will be cleared.

=cut

sub
init(@)
{
    my $self = shift;

    # Clear out existing data.
    $self->{"DATA"} = {};

    # Check for new initializer.
    if (scalar(@_)) {
        $self->set(@_);
    }

    return $self;
}

=item get(key)

Return the value of the specified object member.

=cut

sub
get($)
{
    my ($self, $key) = @_;

    if (exists($self->{"DATA"}{$key})) {
        return $self->{"DATA"}{$key};
    } else {
        return undef;
    }
}


=item set(key, value)

Set a member from a key/value pair.

=item set(key => value, key => value, [ ... ])

Set member values based on a hash (or array).

=item set(hashref)

Set member values based on a hash reference.

=cut

sub
set($$)
{
    my $self = shift;
    my %new_data;

    if (!scalar(@_)) {
        return undef;
    }
    if (scalar(@_) == 1) {
        my $hashref = shift;

        if (ref($hashref) eq "HASH") {
            %new_data = %{$hashref};
        } elsif ((ref($hashref) eq "ARRAY") && (scalar(@{$hashref}) % 2 == 0)) {
            %new_data = @{$hashref};
        } else {
            return undef;
        }
    } else {
        %new_data = @_;
    }

    foreach my $key (keys(%new_data)) {
        $self->{"DATA"}{$key} = $new_data{$key};
    }
    return scalar(%new_data);
}


=item serialize()

Return a hash (or hashref) containing all member variables and their values.

=cut

sub
serialize()
{
    my $self = shift;
    my $hashref;

    %{$hashref} = %{$self->{"DATA"}};

    return ((wantarray()) ? (%{$hashref}) : ($hashref));
}

=item to_string()

Return the canonical string representation of the object.

=cut

sub
to_string()
{
    my $self = shift;

    return "{ $self }";
}

=item debug_string()

Return debugging output for the object's contents.

=cut

sub
debug_string()
{
    my $self = shift;

    return sprintf("{ $self:  %s }", join(", ", map { "\"$_\" => \"$self->{DATA}{$_}\"" } sort(keys(%{$self->{"DATA"}}))));
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

Copyright (c) 2003-2010, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

The GNU GPL Document can be found at:
http://www.gnu.org/copyleft/gpl.html

=cut


1;
