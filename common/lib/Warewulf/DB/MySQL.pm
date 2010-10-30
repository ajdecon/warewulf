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

package Warewulf::DB::MySQL;

use Warewulf::Logger;
use Warewulf::Config;
use DBI;


=head1 NAME

Warewulf::DB::MySQL - Database interface to Warewulf

=head1 ABOUT

The Warewulf::DB::MySQL interface to access the MySQL DB type for Warewulf

=head1 SYNOPSIS

    use Warewulf::DB::MySQL;

=cut

=item new(server, databasename, username, password)

Connect to the DB and create the object.

=cut
sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $db_server = shift;
    my $db_name = shift;
    my $db_user = shift;
    my $db_pass = shift;
    my $self;
 
    %{$self} = ();

    &dprint("DATABASE NAME:      $db_name\n");
    &dprint("DATABASE SERVER:    $db_server\n");
    &dprint("DATABASE USER:      $db_user\n");

    $self->{"DBH"} = DBI->connect("DBI:mysql:database=$db_name;host=$db_server", $db_user, $db_pass);
    if ( $self->{"DBH"}) {
        &nprint("Successfully connected to database!\n");
    } else {
        die "Could not connect to DB: $!!\n";
    }

    bless($self, $class);

    return($self);
}


=item query($query_object)

Take a query object and execute it.

=cut
sub
query($$)
{
    my $self = shift;
    my $query = shift;
    my $sql;

    my $table = $query->table();
    my $sql_query;

    if (! $table) {
        return undef;
    }
    if (ref($query) eq "Warewulf::DBQuery::Set") {
        $sql_query = "UPDATE $table SET ";
        $sql_query .= join(", ", map { "$_->[0] = ". $self->{"DBH"}->quote($_->[1]) } $query->set());
        $sql_query .= " ";
        if ($query->match()) {
            $sql_query .= "WHERE ";
            $sql_query .= join(" AND ", map { "$_->[0] ". uc($_->[1]) . ' ' . $self->{"DBH"}->quote($_->[2]) } $query->match());
            $sql_query .= " ";
        }

    } elsif (ref($query) eq "Warewulf::DBQuery::Insert") {
        my (@key, @val);
        foreach my $s ($query->set()) {
            push(@key, $s->[0]);
            push(@val, $s->[1]);
        }
        $sql_query = "INSERT INTO $table (". join(",", @key) .") VALUES (". join(",", map { $self->{"DBH"}->quote($_) } @val) .")";
    } elsif (ref($query) eq "Warewulf::DBQuery::Get") {
        if ($table eq "nodes") {
            $sql_query = "SELECT nodes.id AS id,
                          nodes.name AS name,
                          nodes.description AS description,
                          nodes.notes AS notes,
                          nodes.debug AS debug,
                          nodes.active AS active,
                          clusters.name AS cluster,
                          racks.name AS rack,
                          vnfs.name AS vnfs,
                          GROUP_CONCAT(DISTINCT(masters.name)) AS master,
                          GROUP_CONCAT(DISTINCT(ethernets.hwaddr)) AS hwaddr,
                          GROUP_CONCAT(DISTINCT CONCAT(ethernets.device, ':', ethernets.ipaddr)) AS ipaddr,
                          GROUP_CONCAT(DISTINCT(groups.name)) AS groups
                          FROM nodes
                          LEFT JOIN clusters ON nodes.cluster_id = clusters.id
                          LEFT JOIN racks ON nodes.rack_id = racks.id
                          LEFT JOIN vnfs ON nodes.vnfs_id = vnfs.id
                          LEFT JOIN ethernets ON nodes.id = ethernets.node_id
                          LEFT JOIN nodes_masters ON nodes.id = nodes_masters.node_id
                          LEFT JOIN masters ON nodes_masters.master_id = masters.id
                          LEFT JOIN nodes_groups ON nodes.id = nodes_groups.node_id
                          LEFT JOIN groups ON nodes_groups.group_id = groups.id
                          GROUP BY nodes.id ";

        } elsif ($table eq "clusters") {
            $sql_query = "SELECT clusters.id AS id,
                          clusters.name AS name,
                          clusters.description AS description,
                          clusters.notes AS notes,
                          GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes
                          FROM clusters
                          LEFT JOIN nodes ON clusters.id = nodes.cluster_id
                          GROUP BY clusters.id ";

        } elsif ($table eq "racks") {
            $sql_query = "SELECT racks.id AS id,
                          racks.name AS name,
                          racks.description AS description,
                          racks.notes AS notes,
                          GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes
                          FROM racks
                          LEFT JOIN nodes ON racks.id = nodes.rack_id
                          GROUP BY racks.id ";

        } elsif ($table eq "groups") {
            $sql_query = "SELECT groups.id AS id,
                          groups.name AS name,
                          groups.description AS description,
                          groups.notes AS notes,
                          GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes
                          FROM groups
                          LEFT JOIN nodes_groups ON nodes_groups.group_id = groups.id
                          LEFT JOIN nodes ON nodes_groups.node_id = nodes.id
                          GROUP BY groups.id ";

        } elsif ($table eq "ethernets") {
            $sql_query = "SELECT ethernets.id AS id,
                          ethernets.hwaddr AS hwaddr,
                          ethernets.device AS device,
                          ethernets.ipaddr AS ipaddr,
                          GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes
                          FROM ethernets
                          LEFT JOIN nodes ON ethernets.node_id = nodes.id
                          GROUP BY ethernets.id ";

        } elsif ($table eq "masters") {
            $sql_query = "SELECT masters.id AS id,
                          masters.name AS name,
                          masters.description AS description,
                          masters.notes AS notes,
                          masters.ipaddr AS ipaddr,
                          GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes
                          FROM groups
                          LEFT JOIN nodes_masters ON nodes_masters.master_id = masters.id
                          LEFT JOIN nodes ON nodes_masters.node_id = nodes.id
                          GROUP BY masters.id ";

        }
        if ($query->match()) {
            $sql_query .= "HAVING ";
            $sql_query .= join(" AND ", map { "$_->[0] ". uc($_->[1]) . ' ' . ($_->[2] eq "NULL" ? "NULL" : $self->{"DBH"}->quote($_->[2])) } $query->match());
            $sql_query .= " ";
        }
        if ($query->order()) {
            $sql_query .= "ORDER BY ";
            $sql_query .= join(", ", map { (($_->[1]) ? ("$_->[0] " . uc($_->[1])) : ("$_->[0]")) } $query->order());
            $sql_query .= " ";
        }
        if ($query->limit()) {
            $sql_query .= "LIMIT ";
            $sql_query .= join(", ", map { (($_->[1]) ? ("$_->[0] OFFSET $_->[1]") : ($_->[0])) } $query->limit());
            $sql_query .= " ";
        }
    }

    &dprint("SQL: $sql_query\n");

    my $sth = $self->{"DBH"}->prepare($sql_query);
    $sth->execute();
    if (ref($query) eq "Warewulf::DBQuery::Get") {
        if ($query->function()) {
            while (my $h = $sth->fetchrow_hashref()) {
                foreach my $f ($query->function()) {
                    &$f($h);
                }
            }
        } else {
            return($sth->fetchall_arrayref({}))
        }
    }

    return();
}


1;
