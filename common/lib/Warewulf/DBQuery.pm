

package Warewulf::DBQuery;

use Warewulf::Logger;
use DBI;


=head1 NAME

Warewulf::DBQuery - Database query object interface

=head1 ABOUT

The Warewulf::DBQuery interface provides an abstract interface to the DB object

=head1 SYNOPSIS

    use Warewulf::DBQuery;

=item new(namespace)

Create the object. By default the namespace is that of the caller, but this
can be overridden if requested.

=cut
sub
new($$)
{
    my $proto               = shift;
    my $class               = ref($proto) || $proto;
    my $self;

    %{$self} = ();

    bless($self, $class);

    return $self;
}


=item table(table name)

What table are we querying

=cut
sub
table($)
{
    my $self = shift;
    my $table = shift;

    if ($table) {
        $self->{"TABLE"} = $table;
    }

    return $self->{"TABLE"};
}


=item match(entry to match, operator, constraint)

Add a matching constraint to the query. Allowed operators are:

    =, REGEXP, >, <, >=, <=

=cut
sub
match($$$$)
{
    my $self = shift;
    my $entry = shift;
    my $operator = shift;
    my $constraint = shift;

    if ($entry and $operator and $constraint) {
        push(@{$self->{"MATCHES"}}, [ $entry, $operator, $constraint ]);
    }

    return(@{$self->{"MATCHES"}});
}


=item order(field, ASC/DESC)

How should the results be sorted?

=cut
sub
order($$$)
{
    my $self = shift;
    my $field = shift;
    my $order = shift;

    if ($field and $order) {
        push(@{$self->{"SORT"}}, [ $field, $order ]);
    }

    return(@{$self->{"SORT"}});
}


=item set(column name, value)

Set the column data to the defined value

=cut
sub
set($$$)
{
    my $self = shift;
    my $column = shift;
    my $value = shift;

    if ($column and $value) {
        push(@{$self->{"SET"}}, [ $column, $value]);
    }

    return(@{$self->{"SET"}});
}


=item limit(start, count)

How many rows should be returned? The first argument is the first row to
display starting at zero, and the second argument is a count from the first.

=cut
sub
limit($$$)
{
    my $self = shift;
    my $start = shift;
    my $end = shift;

    if ($start) {
        push(@{$self->{"LIMIT"}}, [ $start, $end]);
    }

    return(@{$self->{"LIMIT"}});
}


1;
