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

=head1 DESCRIPTION

C<Warewulf::DB::MySQL> provides the MySQL implementation of the
C<Warewulf::DB> interface.  This interface abstracts out the
underlying data store from the rest of the Warewulf applications and
services.  No application code changes should be required to changes
backend data stores.

All C<Warewulf::DB> implementations are singletons, so there will only
ever be a single connection to the data store backend.

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

=item find_serialized($type, $key, $val1, $val2, $val3);

Get object(s) by type and index value

=cut
sub
find_serialized($$$@)
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
    $sql_query .= "AND lookup.key = ". $self->{"DBH"}->quote($type) ." ";
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



my $obj = Warewulf::DB::SQL::MySQL->new();
$obj->find_serialized("node", "name", "n0000", "n0001");



exit;


















=item query($query_object)

Take a query object and execute it.

=cut

sub
query($$)
{
    my $self = shift;
    my $query = shift;
    my ($table, $sql, $sql_query);

    $table = $query->table();
    if (! $table) {
        return undef;
    }

    if ($query->action() eq "SET") {
        $sql_query = "UPDATE $table SET ";
        $sql_query .= join(", ", map { "$_->[0] = ". ($_->[1] ? $self->{"DBH"}->quote($_->[1]) : "NULL") } $query->set());
        $sql_query .= " ";
        if ($query->match()) {
            $sql_query .= "WHERE ";
            my @matches;
            foreach my $m ($query->match()) {
                $key = $m->[0];
                $oper = uc($m->[1]);
                $value = $m->[2];
                my $string;
                if (ref($value) eq "ARRAY") {
                    $string = join(",", map { $self->{"DBH"}->quote($_) } @{$value});
#                    push(@matches, "$key ". uc($oper) ." (". join(",", map { $self->{"DBH"}->quote($_) } @{$value}) .")");
                } else {
                    $string = $self->{"DBH"}->quote($value);
#                    push(@matches, "$key ". uc($oper) ." ". $self->{"DBH"}->quote($value));
                }
                if ($oper eq "IN") {
                    push(@matches, "$key IN ($string)");
                } else {
                    push(@matches, "$key $oper $string");
                }
            }
            $sql_query .= join(" AND ", @matches);
            $sql_query .= " ";
        }

    } elsif ($query->action() eq "INSERT") {
        my (@key, @val);
        foreach my $s ($query->set()) {
            push(@key, $s->[0]);
            push(@val, $s->[1]);
        }
        $sql_query = "INSERT INTO $table (". join(",", @key) .") VALUES (". join(",", map { $self->{"DBH"}->quote($_) } @val) .")";
    } elsif ($query->action() eq "GET") {
        if ($table eq "nodes") {
            $sql_query = "SELECT nodes.id AS id, ";
            $sql_query .= "nodes.name AS name, ";
            $sql_query .= "nodes.description AS description, ";
            $sql_query .= "nodes.notes AS notes, ";
            $sql_query .= "nodes.debug AS debug, ";
            $sql_query .= "nodes.active AS active, ";
            $sql_query .= "nodes.vnfs_id AS vnfs_id, ";
            $sql_query .= "nodes.cluster_id AS cluster_id, ";
            $sql_query .= "nodes.rack_id AS rack_id, ";
            $sql_query .= "clusters.name AS cluster, ";
            $sql_query .= "racks.name AS rack, ";
            $sql_query .= "vnfs.name AS vnfs, ";
            $sql_query .= "CONCAT_WS('.', nodes.name, clusters.name) AS nodename, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(masters.name)) AS master, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(ethernets.hwaddr)) AS hwaddr, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT CONCAT(ethernets.device, ':', ethernets.ipaddr, '/', ethernets.netmask)) AS ifconfig, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(groups.name)) AS groups ";
            $sql_query .= "FROM nodes ";
            $sql_query .= "LEFT JOIN clusters ON nodes.cluster_id = clusters.id ";
            $sql_query .= "LEFT JOIN racks ON nodes.rack_id = racks.id ";
            $sql_query .= "LEFT JOIN vnfs ON nodes.vnfs_id = vnfs.id ";
            $sql_query .= "LEFT JOIN ethernets ON nodes.id = ethernets.node_id ";
            $sql_query .= "LEFT JOIN nodes_masters ON nodes.id = nodes_masters.node_id ";
            $sql_query .= "LEFT JOIN masters ON nodes_masters.master_id = masters.id ";
            $sql_query .= "LEFT JOIN nodes_groups ON nodes.id = nodes_groups.node_id ";
            $sql_query .= "LEFT JOIN groups ON nodes_groups.group_id = groups.id ";
            $sql_query .= "GROUP BY nodes.id ";

        } elsif ($table eq "clusters") {
            $sql_query = "SELECT clusters.id AS id, ";
            $sql_query .= "clusters.name AS name, ";
            $sql_query .= "clusters.description AS description, ";
            $sql_query .= "clusters.notes AS notes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.id)) AS nodeids ";
            $sql_query .= "FROM clusters ";
            $sql_query .= "LEFT JOIN nodes ON clusters.id = nodes.cluster_id ";
            $sql_query .= "GROUP BY clusters.id ";

        } elsif ($table eq "racks") {
            $sql_query .= "SELECT racks.id AS id, ";
            $sql_query .= "racks.name AS name, ";
            $sql_query .= "racks.description AS description, ";
            $sql_query .= "racks.notes AS notes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.id)) AS nodeids ";
            $sql_query .= "FROM racks ";
            $sql_query .= "LEFT JOIN nodes ON racks.id = nodes.rack_id ";
            $sql_query .= "GROUP BY racks.id ";

        } elsif ($table eq "groups") {
            $sql_query = "SELECT groups.id AS id, ";
            $sql_query .= "groups.name AS name, ";
            $sql_query .= "groups.description AS description, ";
            $sql_query .= "groups.notes AS notes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.id)) AS nodeids ";
            $sql_query .= "FROM groups ";
            $sql_query .= "LEFT JOIN nodes_groups ON nodes_groups.group_id = groups.id ";
            $sql_query .= "LEFT JOIN nodes ON nodes_groups.node_id = nodes.id ";
            $sql_query .= "GROUP BY groups.id ";

        } elsif ($table eq "ethernets") {
            $sql_query = "SELECT ethernets.id AS id, ";
            $sql_query .= "ethernets.hwaddr AS hwaddr, ";
            $sql_query .= "ethernets.device AS device, ";
            $sql_query .= "ethernets.ipaddr AS ipaddr, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.id)) AS nodeids ";
            $sql_query .= "FROM ethernets ";
            $sql_query .= "LEFT JOIN nodes ON ethernets.node_id = nodes.id ";
            $sql_query .= "GROUP BY ethernets.id ";

        } elsif ($table eq "masters") {
            $sql_query = "SELECT masters.id AS id, ";
            $sql_query .= "masters.name AS name, ";
            $sql_query .= "masters.description AS description, ";
            $sql_query .= "masters.notes AS notes, ";
            $sql_query .= "masters.ipaddr AS ipaddr, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.id)) AS nodeids ";
            $sql_query .= "FROM groups ";
            $sql_query .= "LEFT JOIN nodes_masters ON nodes_masters.master_id = masters.id ";
            $sql_query .= "LEFT JOIN nodes ON nodes_masters.node_id = nodes.id ";
            $sql_query .= "GROUP BY masters.id ";

        } elsif ($table eq "vnfs") {
            $sql_query = "SELECT vnfs.id AS id, ";
            $sql_query .= "vnfs.name AS name, ";
            $sql_query .= "vnfs.description AS description, ";
            $sql_query .= "vnfs.notes AS notes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes, ";
            $sql_query .= "GROUP_CONCAT(DISTINCT(nodes.id)) AS nodeids ";
            $sql_query .= "FROM vnfs ";
            $sql_query .= "LEFT JOIN nodes ON nodes.vnfs_id = vnfs.id ";
            $sql_query .= "GROUP BY vnfs.id ";

        }
        if ($query->match()) {
            $sql_query .= "HAVING ";
            my @matches;
            foreach my $m ($query->match()) {
                my $string;
                $key = $m->[0];
                $oper = uc($m->[1]);
                $value = $m->[2];
                if ($value) {
                    if (ref($value) eq "ARRAY") {
                        $string = join(",", map { $self->{"DBH"}->quote($_) } @{$value});
                    } else {
                        $string = $self->{"DBH"}->quote($value);
                    }
                    if ($oper eq "IN") {
                        push(@matches, "$key IN ($string)");
                    } else {
                        push(@matches, "$key $oper $string");
                    }
                } else {
                    push(@matches, "$key IS NULL");
                }
            }
            $sql_query .= join(" AND ", @matches);
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

    &dprint("$sql_query\n");

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
