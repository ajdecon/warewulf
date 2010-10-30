

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
    my @set = $query->set();
    my @matches = $query->match();
    my @orders = $query->order();
    my @limits = $query->limit();
    my @functions = $query->function();
    my $sql_query;

    if (! $table) {
        return undef;
    }
    if (@set) {
        $sql_query = "UPDATE $table SET ";
        $sql_query .= join(", ", map { "$_->[0] = '". $self->{"DBH"}->quote($_->[1]) ."'" } @set);
        if (@matches) {
            $sql_query .= "WHERE ";
            $sql_query .= join(" AND ", map { "$table.$_->[0] ". uc($_->[1]) . ' ' . $self->{"DBH"}->quote($_->[2]) } @matches);
            $sql_query .= " ";
        }
    } else {
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
                          GROUP_CONCAT(DISTINCT(ethernets.hwaddr)) AS hwaddr,
                          GROUP_CONCAT(DISTINCT CONCAT(ethernets.device, ':', ethernets.ipaddr)) AS ipaddr,
                          GROUP_CONCAT(DISTINCT(groups.name)) AS groups
                          FROM nodes
                          LEFT JOIN clusters ON nodes.cluster_id = clusters.id
                          LEFT JOIN racks ON nodes.rack_id = racks.id
                          LEFT JOIN vnfs ON nodes.vnfs_id = vnfs.id
                          LEFT JOIN ethernets ON nodes.id = ethernets.node_id
                          LEFT JOIN nodes_groups ON nodes.id = nodes_groups.node_id
                          LEFT JOIN groups ON nodes_groups.group_id = groups.id ";

        } elsif ($table eq "clusters") {
            $sql_query = "SELECT clusters.id AS id,
                          clusters.name AS name,
                          clusters.description AS description,
                          clusters.notes AS notes,
                          GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes
                          FROM clusters
                          LEFT JOIN nodes ON clusters.id = nodes.cluster_id ";

        } elsif ($table eq "racks") {
            $sql_query = "SELECT racks.id AS id,
                          racks.name AS name,
                          racks.description AS description,
                          racks.notes AS notes,
                          GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes
                          FROM racks
                          LEFT JOIN nodes ON racks.id = nodes.rack_id ";

        } elsif ($table eq "groups") {
            $sql_query = "SELECT groups.id AS id,
                          groups.name AS name,
                          groups.description AS description,
                          groups.notes AS notes,
                          GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes
                          FROM groups
                          LEFT JOIN nodes_groups ON nodes_groups.group_id = groups.id
                          LEFT JOIN nodes ON nodes_groups.node_id = nodes.id ";

        } elsif ($table eq "ethernets") {
            $sql_query = "SELECT ethernets.id AS id,
                          ethernets.hwaddr AS hwaddr,
                          ethernets.device AS device,
                          ethernets.ipaddr AS ipaddr,
                          GROUP_CONCAT(DISTINCT(nodes.name)) AS nodes
                          FROM ethernets
                          LEFT JOIN nodes ON ethernets.node_id = nodes.id ";

        }

        if (@matches) {
            $sql_query .= "WHERE ";
            $sql_query .= join(" AND ", map { "$_->[0] ". uc($_->[1]) . ' ' . $self->{"DBH"}->quote($_->[2]) } @matches);
            $sql_query .= " ";
        }

        $sql_query .= "GROUP BY $table.id ";

        if (@orders) {
            $sql_query .= "ORDER BY ";
            $sql_query .= join(", ", map { (($_->[1]) ? ("$_->[0] " . uc($_->[1])) : ("$_->[0]")) } @orders);
            $sql_query .= " ";
        }
        if (@limits) {
            $sql_query .= "LIMIT ";
            $sql_query .= join(", ", map { (($_->[1]) ? ("$_->[0] OFFSET $_->[1]") : ($_->[0])) } @limits);
            $sql_query .= " ";
        }
    }

    my $sth = $self->{"DBH"}->prepare($sql_query);
    $sth->execute();
    while (my $h = $sth->fetchrow_hashref()) {
        if (@functions) {
            foreach my $f (@functions) {
                &$f($h);
            }
        }
#        foreach (keys %{$h}) {
#            print "$_: $h->{$_}\n";
#        }

    }

}






1;
