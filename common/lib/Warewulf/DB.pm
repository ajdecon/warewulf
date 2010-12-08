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

package Warewulf::DB;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::Config;
use Warewulf::DB::MySQL;
use DBI;


=head1 NAME

Warewulf::DB - Database interface

=head1 ABOUT

The Warewulf::DB interface simplies typically used DB calls.

=head1 SYNOPSIS

    use Warewulf::DB;

    print "creating new object\n";
    my $db = Warewulf::DB::SQL::MySQL->new();
    my $entity = $db->new_object();

    print "Setting some stuffs\n";
    $entity->set("name", "gmk00");

    print "persisting\n";
    $db->persist($entity);

    print "adding lookups\n";
    $db->add_lookup($entity, "node", "name", "gmk00");
    $db->add_lookup($entity, "node", "status", "READY");

    print "Getting stuffs\n";

    my $objectSet = $db->get_objects("node", "name", "gmk00");
    foreach my $o ( $objectSet->get_list() ) {
        print "name: ". $o->get("name") ."\n";
    }


=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto = shift;
    my $config = Warewulf::Config->new();
    my $db_engine = $config->get("database type") || "sql";

    if ($db_engine eq "sql") {
        return(Warewulf::DB::SQL->new(@_));
    } else {
        &eprint("Could not load DB type: $db_engine\n");
        exit 1;
    }

    return();
}





1;

