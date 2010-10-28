

package Warewulf::DBQuery;

use Warewulf::Logger;
use DBI;


=head1 NAME

Warewulf::DBQuery - Database query object interface

=head1 ABOUT

The Warewulf::DBQuery interface provides an abstract interface to the DB object

=head1 SYNOPSIS

    use Warewulf::DBQuery;

=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto               = shift;
    my $class               = ref($proto) || $proto;
    my $self;

    %{$self} = ();

    bless($self, $class);

    return($self);
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

    push(@{$self->{"MATCHES"}}, [ $entry, $operator, $constraint ]);

}


=item sortby(field, ASC/DESC)

How should the results be sorted?

=cut
sub
sortby($$$)
{
    my $self = shift;
    my $field = shift;
    my $order = shift;

    push(@{$self->{"SORTBY"}}, [ $field, $order ]);

}


=item return(column name, present)

How should the data be presented? By default it will just return the string
corresponding to the entry requested, but you can also do a COUNT of the
entries found, or return the MAX entry.

=cut
sub
return($$$)
{
    my $self = shift;
    my $column = shift;
    my $present = shift;

    push(@{$self->{"RETURN"}}, [ $column, $present]);

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

    push(@{$self->{"LIMIT"}}, [ $start, $end]);

}





1;
