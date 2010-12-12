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

Warewulf::Object - Warewulf's generic object class and the ancestor of
all other classes.

=head1 SYNOPSIS

    use Warewulf::Object;

    my $obj = Warewulf::Object->new();

    $obj->set("name", "Bob");
    $obj->set("type" => "person", "active" => 1);
    $display = $obj->to_string();
    $dbg = $obj->debug_string();
    printf("%s is named %s\n", $display, $obj->name());

    $data_store->persist($obj->serialize());

=head1 DESCRIPTION

C<Warewulf::Object> is the base class from which all other Warewulf
objects are derived.  It provides a simple constructor, an
initializer, get/set methods, string conversion, and a catch-all
AUTOLOAD member function for turning arbitrary method calls into
accessors.

=head1 METHODS

=over 4

=item new()

Instantiate an object.  Any initializer accepted by the C<set()>
method may also be passed to C<new()>.

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

Initialize an object.  All data currently stored in the object will be
cleared.  Any initializer accepted by the C<set()> method may also be
passed to C<init()>.

=cut

sub
init(@)
{
    my $self = shift;

    # Clear out existing data.
    $self->{"DATA"} = {};

    $self->set("type", $self->type());

    # Check for new initializer.
    if (scalar(@_)) {
        $self->set(@_);
    }

    return $self;
}

=item get(I<key>)

Return the value of the specified member variable I<key>.  Returns
C<undef> if I<key> is not a member variable of the object.  No
distinction is made between "member is not present" and "member is
present but undefined."

=cut

sub
get($)
{
    my ($self, $key) = @_;
    my $uc_key = uc($key);

    if (exists($self->{"DATA"}{$uc_key})) {
        return $self->{"DATA"}{$uc_key};
    } else {
        return undef;
    }
}


=item set(I<key>, I<value>)

=item set(I<key> => I<value>, I<key> => I<value>, [ ... ])

=item set(I<hashref>)

Set member variable(s) from a key/value pair, a hash, an array, or a
hash/array reference.  Returns the last value set or C<undef> if
invoked improperly.

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
        my $uc_key = uc($key);
        $self->{"DATA"}{$uc_key} = $new_data{$key};
    }
}


=item get_hash()

Return a hash (or hashref) containing all member variables and their
values.  This is particularly useful for converting an object into its
constituent components; e.g., to be stored in a database.

=cut

sub
get_hash()
{
    my $self = shift;
    my $hashref;

    %{$hashref} = %{$self->{"DATA"}};

    return ((wantarray()) ? (%{$hashref}) : ($hashref));
}

=item to_string()

Return the canonical string representation of the object.  For a
generic object, this is simply the type and pointer value.  Child
classes should override this method intelligently.

=cut

sub
to_string()
{
    my $self = shift;

    return "{ $self }";
}

=item debug_string()

Return debugging output for the object's contents.  For a generic
object, this is the type/pointer value and the member
variables/values.  Child classes should override this method
intelligently.

=cut

sub
debug_string()
{
    my $self = shift;

    return sprintf("{ $self:  %s }", join(", ", map { "\"$_\" => \"$self->{DATA}{$_}\"" } sort(keys(%{$self->{"DATA"}}))));
}

=item I<key>([I<value>])

Any methods not otherwise defined will be automatically translated
into a get/set command, so you can do things like this:

  $obj->title("Set title to this string");
  $name = $obj->name();

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

=item lookups()

Return an array of strings that should be used to create lookup references for
this object (if they exist).

=cut
sub
lookups($)
{
    my $self = shift;

    return(qw(name id));
}


=back

=head1 SEE ALSO

Warewulf::ObjectSet

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
