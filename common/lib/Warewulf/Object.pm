# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::Object;

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

    $key = uc($key);
    if (exists($self->{$key})) {
        if (ref($self->{$key})) {
            return ((wantarray()) ? (@{$self->{$key}}) : ($self->{$key}));
        } else {
            return $self->{$key};
        }
    } else {
        return undef;
    }
}


=item set(I<key>, I<value>, ...)

=item set(I<key>, I<arrayref>)

=item set(I<arrayref>)

=item set(I<hashref>)

Set member variable(s) from a key/value pair, a hash, an array, or a
hash/array reference.  Returns the last value set or C<undef> if
invoked improperly.

=cut

sub
set($$)
{
    my $self = shift;
    my $key = shift;
    my @vals = @_;

    # If we don't even have a key, we have nothing to do.
    if (!defined($key)) {
        return undef;
    }

    # If the key is a reference, move it to @vals.  Otherwise, uppercase it.
    if (ref($key)) {
        @vals = ($key);
        $key = undef;
    } else {
        $key = uc($key);
    }

    # If we only got 1 value, it better be a reference.
    if ((scalar(@vals) == 1) && (ref($vals[0]))) {
        my $hashref = $vals[0];

        if (ref($hashref) eq "HASH") {
            # Hashref.  Repopulate our data from scratch and return.
            %{$self} = %{$hashref};
            return $hashref;
        } elsif (ref($hashref) eq "ARRAY") {
            # Arrayref.  Dereference it and process as normal.
            @vals = @{$hashref};
            if (!defined($key)) {
                # Key was in the referenced array.
                $key = uc(shift @vals);
            }
        } else {
            # Any other type of reference is a no-no.
            return undef;
        }
    }

    if (!scalar(@vals)) {
        # We still can't set anything if we have no values.
        return undef;
    } elsif (scalar(@vals) == 1) {
        if (!defined($vals[0])) {
            # Undef.  Remove member.
            delete $self->{$key};
            return undef;
        } else {
            # Just one value.  Set the member directly.
            $self->{$key} = $vals[0];
            return $vals[0];
        }
    } else {
        # Multiple values.  Populate an array(ref).
        delete $self->{$key};
        return $self->add($key, @vals);
    }
}

=item add(I<key>, I<value>, ...)

Add an item to an existing member.  Convert to array if needed.

=cut

sub
add()
{
    my $self = shift;
    my $key = shift;
    my @vals = @_;

    $key = uc($key);
    if (exists($self->{$key})) {
        if (ref($self->{$key}) ne "ARRAY") {
            $self->{$key} = [ $self->{$key} ];
        }
    } else {
        $self->{$key} = [];
    }
    foreach my $newval (@vals) {
        if (!scalar(grep { $_ eq $newval } @{$self->{$key}})) {
            push @{$self->{$key}}, $newval;
        }
    }
    return @{$self->{$key}};
}

=item del(I<key>, [ I<value>, ... ])

Delete one or more items from an array member.  If no values are passed,
delete the member entirely.  Returns the new list of values.

=cut

sub
del()
{
    my $self = shift;
    my $key = shift;
    my @vals = @_;

    if (!defined($key)) {
        # Bad/missing key is an error.
        return undef;
    }
    $key = uc($key);

    if (!exists($self->{$key})) {
        # Nothing there to begin with.
        return undef;
    } elsif (!ref($self->{$key}) || (ref($self->{$key}) ne "ARRAY")) {
        # Anything with which add() or del() is used must be an array.
        @{$self->{$key}} = ($self->{$key});
    }

    if (!scalar(@vals)) {
        # Delete the key entirely.
        delete $self->{$key};
        return ();
    }

    # Remove each element in @vals from the array.
    for (my $i = 0; $i < scalar(@{$self->{$key}}); $i++) {
        if (scalar(grep { $self->{$key}[$i] eq $_ } @vals)) {
            # The current value matches and must be removed.
            splice @{$self->{$key}}, $i, 1;
            $i--;
        }
    }

    # If the array is now empty, remove the key.
    if (!scalar(@{$self->{$key}})) {
        delete $self->{$key};
        return ();
    }
    return @{$self->{$key}};
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

    %{$hashref} = %{$self};

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

    return sprintf("{ $self:  %s }", join(", ", map { "\"$_\" => \"$self->{$_}\"" } sort(keys(%{$self}))));
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

    if ($key =~ /destroy/i) {
        return;
    }
    $key =~ s/.*://;

    if (scalar(@_)) {
        return $self->set($key, @_);
    } else {
        return $self->get($key);
    }
}

=item lookups()

Return an array of strings that should be used to create lookup references for
this object (if they exist).

=cut
sub
lookups($)
{
    return ();
}


=back

=head1 SEE ALSO

Warewulf::ObjectSet

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
