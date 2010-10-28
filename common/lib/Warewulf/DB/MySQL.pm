

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





}






1;
