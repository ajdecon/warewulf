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
