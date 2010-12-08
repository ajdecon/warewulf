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
# $Id: DB.pm 51 2010-11-07 03:16:29Z gmk $
#

package Warewulf::DB::SQL;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::Config;
use Warewulf::DB::SQL::MySQL;
use DBI;


=head1 NAME

Warewulf::DB::SQL - Database interface

=head1 ABOUT

The Warewulf::DB::SQL interface simplies typically used DB calls.

=head1 SYNOPSIS

    use Warewulf::DB::SQL;

=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto = shift;
    my $config = Warewulf::Config->new();
    my $db_engine = $config->get("database driver") || "mysql";

    if ($db_engine eq "mysql") {
        return(Warewulf::DB::SQL::MySQL->new(@_));
    } else {
        &eprint("Could not load DB type: $db_engine\n");
        exit 1;
    }

    return();
}





1;

