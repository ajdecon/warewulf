

package Warewulf::Provision::DataStore::MySQL;

use Warewulf::Logger;
use Warewulf::Config;
use Warewulf::Node;
use Warewulf::NodeSet;
use DBI;


=head1 NAME

Warewulf::Provision::DataStore::MySQL - Database interface to Warewulf

=head1 ABOUT

The Warewulf::ProvisionDataStore::MySQL interface to access the MySQL DB type for Warewulf

=head1 SYNOPSIS

    use Warewulf::Provision::DataStore::MySQL;

=cut

=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self;
 
    %{$self} = ();

    my $config = Warewulf::Config->new();
    my $driver = $config->get("database driver") || "mysql";
    my $database = $config->get("database name") || "warewulf";
    my $host = $config->get("database server") || "localhost";
    my $user = $config->get("database user") || "root";
    my $password = $config->get("database password") || "";

    &dprint("DATABASE DRIVER:    $driver\n");
    &dprint("DATABASE NAME:      $database\n");
    &dprint("DATABASE SERVER:    $host\n");
    &dprint("DATABASE USER:      $user\n");

    $self->{"DBH"} = DBI->connect("DBI:$driver:database=$database;host=$host", $user, $passwd);
    if ( $self->{"DBH"}) {
        &nprint("Successfully connected to database!\n");
    } else {
        die "Could not connect to DB: $!!\n";
    }

    bless($self, $class);

    return($self);
}

=item dbh()

Return the raw database handle

=cut
sub
dbh($)
{
    return($self->{"DBH"});
}


=item get_nodes($sql_where_statement,@sql_where_args)

Return a NodeSet (as defined by Warewulf::NodeSet) which contains
in it a set of Node objects (as defined by Warewulf::Node) for
each of the found nodes in the passed SQL WHERE clause.

=cut
sub
get_nodes($$$)
{
    my $self = shift;
    my $where = shift || "";
    my @args = @_;
    m;y @return;
    my $nodeset = Warewulf::NodeSet->new();

    my $query = $self->{"DBH"}->prepare("SELECT
                                         nodes.id,
                                         nodes.name,
                                         nodes.cluster,
                                         nodes.rack,
                                         nodes.description,
                                         nodes.notes,
                                         nodes.debug,
                                         nodes.active,
                                         vnfs.name,
                                         GROUP_CONCAT(groups.name SEPARATOR ', ') AS groups,
                                         GROUP_CONCAT(ethernet.ipaddr SEPARATOR ', ') AS ipaddr,
                                         GROUP_CONCAT(ethernet.hwaddr SEPARATOR ', ') AS hwaddr
                                         FROM nodes
                                         LEFT JOIN vnfs ON vnfs.id = nodes.vnfs_id
                                         LEFT JOIN nodes_groups ON nodes_groups.node_id = nodes.id
                                         LEFT JOIN groups ON nodes_groups.group_id = groups.id
                                         LEFT JOIN ethernet ON ethernet.node_id = nodes.id
                                         $where
                                         GROUP BY nodes.id
                                         ORDER BY nodes.cluster,nodes.name");
    $query->execute(@args);
    while(my @n = $query->fetchrow_array()) {
        my $node = Warewulf::Node->new();
        $node->set("id", $n[0]);
        $node->set("name", $n[1]);
        $node->set("cluster", $n[2]);
        $node->set("rack", $n[3]);
        $node->set("description", $n[4]);
        $node->set("notes", $n[5]);
        $node->set("debug", $n[6]);
        $node->set("active", $n[7]);
        $node->set("vnfs", $n[8]);
        $node->set("groups", $n[9]);
        $node->set("ipaddr", $n[10]);
        $node->set("hwaddr", $n[11]);
        $nodeset->add($node);
    }

    return($nodeset);
}


=item get_nodes_by_name($string)

Return node database ids matching string criteria

=cut
sub
get_nodes_by_name($$)
{
    my $self = shift;
    my $string = shift;

    if ($string) {
        return($self->get_nodes("WHERE nodes.name REGEXP ?", "^$string\$"));
    }

    return();
}


=item get_nodes_by_cluster($string)

Return node database ids matching string criteria

=cut
sub
get_nodes_by_cluster($$)
{
    my $self = shift;
    my $string = shift;

    if ($string) {
        return($self->get_nodes("WHERE nodes.cluster REGEXP ?", "^$string\$"));
    }

    return();
}


=item get_nodes_by_vnfs($string)

Return node database ids matching string criteria

=cut
sub
get_nodes_by_vnfs($$)
{
    my $self = shift;
    my $string = shift;

    if ($string) {
        return($self->get_nodes("WHERE vnfs.name REGEXP ?", "^$string\$"));
    }

    return();
}


=item get_nodes_by_group($string)

Return node database ids matching string criteria

=cut
sub
get_nodes_by_group($$)
{
    my $self = shift;
    my $string = shift;
    my @return;

    if ($string) {
        return($self->get_nodes("WHERE groups.name REGEXP ?", "^$string\$"));
    }

    return();
}


=item get_nodes_by_hwaddr($string)

Return node database ids matching string criteria

=cut
sub
get_nodes_by_hwaddr($$)
{
    my $self = shift;
    my $string = shift;
    my @return;

    if ($string) {
        return($self->get_nodes("WHERE ethernet.hwaddr REGEXP ?", "^$string\$"));
    }

    return();
}


=item get_nodes_by_ipaddr($string)

Return node database ids matching string criteria

=cut
sub
get_nodes_by_ipaddr($$)
{
    my $self = shift;
    my $string = shift;
    my @return;

    if ($string) {
        return($self->get_nodes("WHERE ethernet.ipaddr REGEXP ?", "^$string\$"));
    }

    return();
}


=item set_node_name($node_object, $string)

=cut
sub
set_node_name($$$)
{
    my $self = shift;
    my $obj = shift;
    my $string = shift;

    foreach my $n ($obj->iterate()) {
        my $query = $self->{"DBH"}->prepare("UPDATE nodes SET name = ?, update_time = ? WHERE id = ?");
        $query->execute($string, time(), $n->get("id"));
        $n->set("name", $string);
    }
}


=item set_node_cluster($node_object, $string)

=cut
sub
set_node_cluster($$$)
{
    my $self = shift;
    my $obj = shift;
    my $string = shift;

    foreach my $n ($obj->iterate()) {
        my $query = $self->{"DBH"}->prepare("UPDATE nodes SET cluster = ?, update_time = ? WHERE id = ?");
        $query->execute($string, time(), $n->get("id"));
        $n->set("cluster", $string);
    }
}


=item set_node_rack($node_object, $string)

=cut
sub
set_node_rack($$$)
{
    my $self = shift;
    my $obj = shift;
    my $string = shift;

    foreach my $n ($obj->iterate()) {
        my $query = $self->{"DBH"}->prepare("UPDATE nodes SET rack = ?, uptime_time = ? WHERE id = ?");
        $query->execute($string, time(), $n->get("id"));
        $n->set("rack", $string);
    }
}


=item set_node_description($node_object, $string)

=cut
sub
set_node_description($$$)
{
    my $self = shift;
    my $obj = shift;
    my $string = shift;

    foreach my $n ($obj->iterate()) {
        my $query = $self->{"DBH"}->prepare("UPDATE nodes SET description = ?, uptime_time = ? WHERE id = ?");
        $query->execute($string, time(), $n->get("id"));
        $n->set("description", $string);
    }
}


=item set_node_notes($node_object, $string)

=cut
sub
set_node_notes($$$)
{
    my $self = shift;
    my $obj = shift;
    my $string = shift;

    foreach my $n ($obj->iterate()) {
        my $query = $self->{"DBH"}->prepare("UPDATE nodes SET notes = ?, uptime_time = ? WHERE id = ?");
        $query->execute($string, time(), $n->get("id"));
        $n->set("notes", $string);
    }
}


=item set_node_debug($node_object, $string)

=cut
sub
set_node_debug($$$)
{
    my $self = shift;
    my $obj = shift;
    my $string = shift;

    foreach my $n ($obj->iterate()) {
        my $query = $self->{"DBH"}->prepare("UPDATE nodes SET debug = ?, uptime_time = ? WHERE id = ?");
        $query->execute($string, time(), $n->get("id"));
        $n->set("debug", $string);
    }
}


=item set_node_active($node_object, $string)

=cut
sub
set_node_active($$$)
{
    my $self = shift;
    my $obj = shift;
    my $string = shift;

    foreach my $n ($obj->iterate()) {
        my $query = $self->{"DBH"}->prepare("UPDATE nodes SET active = ?, uptime_time = ? WHERE id = ?");
        $query->execute($string, time(), $n->get("id"));
        $n->set("active", $string);
    }
}


=item set_node_vnfs($node_object, $string)

=cut
sub
set_node_vnfs($$$)
{
    my $self = shift;
    my $obj = shift;
    my $string = shift;

    my $query = $self->{"DBH"}->prepare("UPDATE nodes SET
                                         nodes.vnfs_id = (SELECT id FROM vnfs WHERE name = ?),
                                         nodes.update_time = ?
                                         WHERE nodes.id = ?");

    $query->execute($string, time(), $obj->get("id"));

    $obj->set("vnfs", $string);
}








1;
