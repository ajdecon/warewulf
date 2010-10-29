

package Warewulf::DB;

use Warewulf::Util;
use Warewulf::Logger;
use DBI;


=head1 NAME

Warewulf::DB - Database interface

=head1 ABOUT

The Warewulf::DB interface simplies typically used DB calls.

=head1 SYNOPSIS

    use Warewulf::DB;

The interface provides the following interface schema:

        Query field       Return type

    Node
        name            : string
        description     : string
        notes           : string
        debug           : string
        active          : string
        cluster         : string
        rack            : string
        vnfs            : string
        hwaddr          : list
        ipaddr          : list
        group           : list

    cluster
        name            : string
        description     : string
        notes           : string
        active          : string
        node            : list

    rack
        name            : string
        description     : string
        notes           : string
        active          : string
        node            : list

    modules
        name            : string
        description     : string
        notes           : string
        active          : string
        script          : long text
        node            : list

    ethernet
        name            : string
        description     : string
        notes           : string
        active          : string
        device          : string



=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto               = shift;
    my $class               = ref($proto) || $proto;
    my $self;

    %{$self} = ();

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


=item host($hostname)

Set the DB host

=cut
sub
host($$)
{
    my $self                = shift;
    my $value               = shift;

    if ( $value ) {
        $self->{"HOST"} = $value;
    }

    return($self->{"HOST"});
}

=item database($database)

Set the DB name

=cut
sub
database($$)
{
    my $self                = shift;
    my $value               = shift;

    if ( $value ) {
        $self->{"DATABASE"} = $value;
    }

    return($self->{"DATABASE"});
}

=item driver($driver)

Set the DB driver type (eg. mysql)

=cut
sub
driver($$)
{
    my $self                = shift;
    my $value               = shift;

    if ( $value ) {
        $self->{"DRIVER"} = $value;
    }

    return($self->{"DRIVER"});
}

=item user($username)

Set the DB username

=cut
sub
user($$)
{
    my $self                = shift;
    my $value               = shift;

    if ( $value ) {
        $self->{"USER"} = $value;
    }

    return($self->{"USER"});
}

=item passwd($password)

Set the DB password

=cut
sub
passwd($$)
{
    my $self                = shift;
    my $value               = shift;

    if ( $value ) {
        $self->{"PASSWD"} = $value;
    }

    return($self->{"PASSWD"});
}

=item connect()

Connect to the DB server

=cut
sub
connect($)
{
    my $self                = shift;
    my $database            = $self->database() || $main::db_database;
    my $driver              = $self->driver() || $main::db_driver || "mysql";
    my $host                = $self->host() || $main::db_host || "localhost";
    my $user                = $self->user() || $main::db_user || "root";
    my $passwd              = $self->passwd() || $main::db_passwd;

    if ( $driver and $database ) {
        $self->{"DBH"} = $dbh = DBI->connect("DBI:$driver:database=$database;host=$host", $user, $passwd);
        if ( $self->{"DBH"} ) {
        } else {
            die "Could not connect to DB: $!!\n";
        }
    } else {
        die "Driver and/or database undefined!\n";
    }

    return(1);
}

=item command($string)

Run a SQL command and return if it didn't throw an error

=cut
sub
command(@)
{
    my $self                = shift;
    my $sql                 = shift;
    my @vars                = @_;
    my $return;

    if ( $sql ) {
        eval {
            $self->{"STH"} = $self->{"DBH"}->prepare($sql);
            $self->{"STH"}->execute(@vars);
            $self->{"CMD"} = $sql;
        };
        if ( ! $self->{"STH"}->err ) {
            $return = 1;
        }
    }

    return($return);
}

=item test($string)

Run a SQL command and return if the SQL command returns at least 1 line with no error

=cut
sub
test(@)
{
    my $self                = shift;
    my $sql                 = shift;
    my @vars                = @_;
    my $return;

    if ( $sql ) {
        eval {
            $self->{"STH"} = $self->{"DBH"}->prepare($sql);
            $self->{"STH"}->execute(@vars);
            $self->{"CMD"} = $sql;
        };
        if ( $self->{"STH"}->rows > 0 and ! $self->{"STH"}->err ) {
            $return = 1;
        }
    }

    return($return);
}

=item error()

Print any pending SQL errors

=cut
sub
error
{
    my $self                = shift;

    if ( $self->{"STH"}->err ) {
        return($self->{"CMD"} .": ". $self->{"STH"}->errstr);
    }

    return();
}

=item fetch_row()

Fetch any pending row, and join if there are multiple fields away.

=cut
sub
fetch_row($)
{
    my $self                = shift;

    if ( exists($self->{"STH"}) ) {
        return(wantarray ? $self->{"STH"}->fetchrow_array() : join(",", $self->{"STH"}->fetchrow_array()));
    }
    return();
}

=item get()

Run an SQL command and return the resule in one action.

=cut
sub
get(@)
{
    my $self                = shift;
    my @args                = @_;

    $self->command(@args);
    return($self->fetch_row());
}


=item rows()

Count the number of rows returned

=cut
sub
rows(@)
{
    my $self                = shift;
    my @args                = @_;

    return($self->{"STH"}->rows());
}



1;

