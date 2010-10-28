

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

    my $from = $query->get_namespace();
    my @returns = $query->get_returns();
    my @matches = $query->get_matches();
    my @sorts = $query->get_sorts();
    my @limits = $query->get_limits();

    if (@returns and $from) {
        $sql = "SELECT ";
        $sql .= join(", ", map { (($_->[1]) ? (uc($_->[1]) ."($_->[0]) AS $_->[0]") : ($_->[0])) } $query->get_returns());

        $sql .= " FROM $from ";

        if (@matches) {
            $sql .= "WHERE ";
            $sql .= join(", ", map { "$_->[0] ". uc($_->[1]) ." $_->[2]" } @matches);
            $sql .= " ";
        }

        if (@sorts) {
            $sql .= "ORDER BY ";
            $sql .= join(", ", map { (($_->[1]) ? ("$_->[0] $_->[1]") : ($_->[0])) } @sorts);
            $sql .= " ";
        }

        if (@limits) {
            $sql .= "LIMIT ";
            $sql .= join(", ", map { (($_->[1]) ? ("$_->[1] OFFSET $_->[0]") : ($_->[0])) } @limits);
            $sql .= " ";
        }

print "$sql\n";

    } else {
        &lprint(DEBUG, "DB->execute called with a query that didn't want to return anything\n");
        return;
    }

}






1;
