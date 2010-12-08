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
# $Id: MySQL.pm 62 2010-11-11 16:01:03Z gmk $
#

package Warewulf::DB::SQL::MySQL;

use Warewulf::Config;
use Warewulf::DB;
use Warewulf::Logger;
use DBI;

# Declare the singleton
my $singleton;

=head1 NAME

Warewulf::DB::MySQL - MySQL Database interface to Warewulf

=head1 SYNOPSIS

    use Warewulf::DB::MySQL;

    my $db = Warewulf::DB->new("mysql");
    my %data = $db->get_serialized("node", "name", "n0000", "n0001");

=head1 DESCRIPTION

=cut

=item new()

Connect to the DB and create the object singleton.

=cut

sub
new()
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $config = Warewulf::Config->new();
    my $db_server = $config->get("database server");
    my $db_name = $config->get("database name");
    my $db_user = $config->get("database user");
    my $db_pass = $config->get("database password");
 
    if ($singleton && exists($singleton->{"DBH"}) && $singleton->{"DBH"}) {
        &dprint("DB Singleton exists, not going to initialize\n");
    } else {
        %{$singleton} = ();

        &dprint("DATABASE NAME:      $db_name\n");
        &dprint("DATABASE SERVER:    $db_server\n");
        &dprint("DATABASE USER:      $db_user\n");

        $singleton->{"DBH"} = DBI->connect("DBI:mysql:database=$db_name;host=$db_server", $db_user, $db_pass);
        if ( $singleton->{"DBH"}) {
            &nprint("Successfully connected to database!\n");
        } else {
            die "Could not connect to DB: $!!\n";
        }

        bless($singleton, $class);
    }

    return $singleton;
}

=item get_serialized($type, $field, $val1, $val2, $val3);

Get object(s) by type, field and index values

=cut
sub
get_serialized($$$@)
{
    my $self = shift;
    my $type = shift;
    my $key = shift;
    my @strings = @_;
    my %return;

    my $sql_query;

    $sql_query  = "SELECT ";
    $sql_query .= "datastore.id AS id, ";
    $sql_query .= "datastore.serialized AS serialized ";
    $sql_query .= "FROM datastore ";
    $sql_query .= "LEFT JOIN lookup ON lookup.object_id = datastore.id ";
    $sql_query .= "WHERE lookup.type = ". $self->{"DBH"}->quote($type) ." ";
    $sql_query .= "AND lookup.field = ". $self->{"DBH"}->quote($key) ." ";
    $sql_query .= "AND lookup.value IN (". join(",", map { $self->{"DBH"}->quote($_) } @strings) .") ";

    print "$sql_query\n\n";

    my $sth = $self->{"DBH"}->prepare($sql_query);
    $sth->execute();

    while (my $h = $sth->fetchrow_hashref()) {
        my $id = $h->{"id"};
        $return{$id} = $h->{"serialized"};
    }

    return(%return);
}



1;

