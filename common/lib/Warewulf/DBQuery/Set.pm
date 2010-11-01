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

package Warewulf::DBQuery::Set;

use Warewulf::Logger;
use DBI;


=head1 NAME

Warewulf::DBQuery::Set - Database query object interface

=head1 ABOUT

The Warewulf::DBQuery::Set interface provides an abstract interface to the DB object

=head1 SYNOPSIS

    use Warewulf::DBQuery::Set;

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

    if ($entry and $operator and $constraint) {
        push(@{$self->{"MATCHES"}}, [ $entry, $operator, $constraint ]);
    }

    return(@{$self->{"MATCHES"}});
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
        push(@{$self->{"SET"}}, [ $column, $value ]);
    }

    return(@{$self->{"SET"}});
}


1;
