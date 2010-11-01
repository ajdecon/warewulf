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

package Warewulf::DBQuery::Get;

use Warewulf::Logger;
use DBI;


=head1 NAME

Warewulf::DBQuery::Get - Database query object interface

=head1 ABOUT

The Warewulf::DBQuery::Get interface provides an abstract interface to the DB object

=head1 SYNOPSIS

    use Warewulf::DBQuery::Get;

=item new(namespace)

Create the object. By default the namespace is that of the caller, but this
can be overridden if requested.

=cut
sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
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

    if ($entry and $operator) {
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

    if ($field) {
        push(@{$self->{"ORDER"}}, [ $field, $order ]);
    }

    return(@{$self->{"ORDER"}});
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
        push(@{$self->{"LIMIT"}}, [ $start, $end ]);
    }

    return(@{$self->{"LIMIT"}});
}


=item function($function_ref)

Call function for each entry returned in the query

=cut
sub
function($$)
{
    my $self = shift;
    my $function_ref = shift;

    if ($function_ref) {
        push(@{$self->{"FUNCTIONS"}}, $function_ref);
    }

    return(@{$self->{"FUNCTIONS"}});
}


1;
