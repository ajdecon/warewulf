

package Warewulf::DBQuery;

use Warewulf::Logger;
use Warewulf::DBQuery::Get;
use Warewulf::DBQuery::Set;
use Warewulf::DBQuery::Insert;
use DBI;


=head1 NAME

Warewulf::DBQuery - Database query object interface

=head1 ABOUT

The Warewulf::DBQuery is a factory for the various DBQuery interfaces

=head1 SYNOPSIS

    use Warewulf::DBQuery;

=item new(get/set/insert)

This will return the appropriate object as defined by the given string

=cut
sub
new($$)
{
    my $proto = shift;
    my $type = shift;

    if (uc($type) eq "SET") {
        return Warewulf::DBQuery::Set->new();
    } elsif (uc($type) eq "GET") {
        return Warewulf::DBQuery::Get->new();
    } elsif (uc($type) eq "INSERT") {
        return Warewulf::DBQuery::Insert->new();
    }

    return();
}



1;
