

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
    my @order = $query->order();
    my @limits = $query->limit();
    my @joins;

    if ($table) {
        if (@set) {
            $sql .= "UPDATE $table SET ";
            $sql .= join(", ", map { "$_->[0] = '". $self->{"DBH"}->quote($_->[1]) ."'" } @set);
        } else {
            if ($table eq "nodes") {
                $sql .= "SELECT nodes.id AS id,
                                nodes.name AS name,
                                nodes.description AS description,
                                nodes.notes AS notes,
                                nodes.debug AS debug,
                                nodes.active AS active,
                                clusters.name AS cluster,
                                racks.name AS rack,
                                vnfs.name AS vnfs,
                                GROUP_CONCAT(ethernets.id) AS ethernets,
                                GROUP_CONCAT(groups.name) AS groups
                                FROM nodes
                                LEFT JOIN clusters ON nodes.cluster_id = clusters.id
                                LEFT JOIN racks ON nodes.rack_id = racks.id
                                LEFT JOIN vnfs ON nodes.vnfs_id = vnfs.id
                                LEFT JOIN ethernets ON nodes.id = ethernets.node_id
                                LEFT JOIN nodes_groups ON nodes.id = nodes_groups.node_id
                                LEFT JOIN groups ON nodes_groups.group_id = groups.id
                                GROUP BY nodes.id";
            }

        }



    } else {
        # no table name
    }








    if (@get and $from) {
        $sql = "SELECT ";
        $sql .= join(", ", map { (($_->[1]) ? (uc($_->[1]) ."($_->[0]) AS $_->[0]") : ($_->[0])) } @returns);

        $sql .= " FROM $from ";

        if (@matches) {
            $sql .= "WHERE ";
            $sql .= join(" AND ", map { "$_->[0] ". uc($_->[1]) . ' ' . $self->{"DBH"}->quote($_->[2]) } @matches);
            $sql .= " ";
        }

        if (@sorts) {
            $sql .= "ORDER BY ";
            $sql .= join(", ", map { (($_->[1]) ? ("$_->[0] " . uc($_->[1])) : ($_->[0])) } @sorts);
            $sql .= " ";
        }

        if (@limits) {
            $sql .= "LIMIT ";
            $sql .= join(", ", map { (($_->[1]) ? ("$_->[0] OFFSET $_->[1]") : ($_->[0])) } @limits);
            $sql .= " ";
        }

print "$sql\n";

    } else {
        &lprint(DEBUG, "DB->execute called with a query that didn't want to return anything\n");
        return;
    }

}






1;
