

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

    &lprint(DEBUG, "DATABASE NAME:      $db_name\n");
    &lprint(DEBUG, "DATABASE SERVER:    $db_server\n");
    &lprint(DEBUG, "DATABASE USER:      $db_user\n");

    $self->{"DBH"} = DBI->connect("DBI:mysql:database=$db_name;host=$db_server", $db_user, $db_pass);
    if ( $self->{"DBH"}) {
        &lprint(NOTICE, "Successfully connected to database!\n");
    } else {
        die "Could not connect to DB: $!!\n";
    }

    bless($self, $class);

    return($self);
}


=item execute($query_object)

Take a query object and do what it says...

=cut
sub
execute($$)
{
    my $self = shift;
    my $query = shift;
    my $sql;

    my $table = $query->table();
    my @set = $query->set();
    my @matches = $query->match();
    my @orders = $query->order();
    my @limits = $query->limit();
    my $sql_query;
    my $sql_where;
    my $sql_order;
    my $sql_limit;
    my $sql_group;

    if ($table) {
        if (@set) {
            $sql_query .= "UPDATE $table SET ";
            $sql_query .= join(", ", map { "$_->[0] = '". $self->{"DBH"}->quote($_->[1]) ."'" } @set);
        } else {
            if ($table eq "nodes") {
                $sql_query .= "SELECT nodes.id AS id,
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
                                LEFT JOIN groups ON nodes_groups.group_id = groups.id";

                $sql_group = "GROUP BY nodes.id";
            }

        }
        if (@matches) {
            $sql_where .= "WHERE ";
            $sql_where .= join(" AND ", map { "$table.$_->[0] ". uc($_->[1]) . ' ' . $self->{"DBH"}->quote($_->[2]) } @matches);
        }

        if (@orders) {
            $sql_order .= "ORDER BY ";
            $sql_order .= join(", ", map { (($_->[1]) ? ("$_->[0] " . uc($_->[1])) : ("$_->[0]")) } @orders);
        }
        if (@limits) {
            $sql_limit .= "LIMIT ";
            $sql_limit .= join(", ", map { (($_->[1]) ? ("$_->[0] OFFSET $_->[1]") : ($_->[0])) } @limits);
        }


    } else {
        # no table name
    }

print "$sql_query $sql_where $sql_group $sql_order $sql_limit\n";

}






1;
