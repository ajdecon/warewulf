# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: MySQL.pm 62 2010-11-11 16:01:03Z gmk $
#

package Warewulf::DataStore::SQL::MySQL;

use Warewulf::Config;
use Warewulf::Logger;
use Warewulf::DSO;
use Warewulf::Object;
use Warewulf::ObjectSet;
use Warewulf::EventHandler;
use DBI;
use Storable qw(freeze thaw);

# Declare the singleton
my $singleton;

=head1 NAME

Warewulf::DataStore::SQL::MySQL - MySQL Database interface to Warewulf

=head1 SYNOPSIS

    use Warewulf::DataStore::SQL::MySQL;

=head1 DESCRIPTION

    This class should not be instantiated directly.  It is intended to be
    treated as an opaque implementation of the DB interface.

    This class creates a persistant singleton for the application runtime
    which will maintain a consistant database connection from the time that
    the object is constructed.
    
    Documentation for each function should be found in the top level
    Warewulf::DataStore documentation. Any implementation specific documentation
    can be found here.

=cut

sub
serialize($)
{
    my ($self, $hashref) = @_;

    return(freeze($hashref));
}

sub
unserialize($)
{
    my ($self, $serialized) = @_;

    return(thaw($serialized));
}


=item new()

=cut

sub
new()
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    if (! $singleton) {
        $singleton = {};
        bless($singleton, $class);
        $singleton->init();
    }

    return($singleton);
}




sub
init()
{
    my $self = shift;
    my $config = Warewulf::Config->new("database.conf");
    my $db_server = $config->get("database server");
    my $db_name = $config->get("database name");
    my $db_user = $config->get("database user");
    my $db_pass = $config->get("database password");
 
    if ($self && exists($self->{"DBH"}) && $self->{"DBH"}) {
        &dprint("DB Singleton exists, not going to initialize\n");
    } else {

        if ($db_name and $db_server and $db_user) {
            &dprint("DATABASE NAME:      $db_name\n");
            &dprint("DATABASE SERVER:    $db_server\n");
            &dprint("DATABASE USER:      $db_user\n");

            $self->{"DBH"} = DBI->connect("DBI:mysql:database=$db_name;host=$db_server", $db_user, $db_pass);
            if ( $self->{"DBH"}) {
                &iprint("Successfully connected to database!\n");
            } else {
                die "Could not connect to DB: $!!\n";
            }
            $self->{"DBH"}->{mysql_auto_reconnect} = 1;

        } else {
            &dprint("Undefined credentials for database\n");
            return();
        }
    }


    return $self;
}


=item chunk_size()

Return the proper chunk size.

=cut

sub
chunk_size()
{
    my $self = shift;

    my (undef, $max_allowed_packet) =  $self->{"DBH"}->selectrow_array("show variables LIKE 'max_allowed_packet'");

    &dprint("max_allowed_packet: $max_allowed_packet\n");
    &dprint("Returning max_allowed_packet - 786432\n");

    return($max_allowed_packet-786432);
}


=item get_objects($type, $field, $val1, $val2, $val3);

=cut

sub
get_objects($$$@)
{
    my $self = shift;
    my $type = shift;
    my $field = shift;
    my @strings = @_;
    my $objectSet;
    my @query_opts;

    $objectSet = Warewulf::ObjectSet->new();

    my $sql_query;

    if ($type) {
        push(@query_opts, "datastore.type = ". $self->{"DBH"}->quote($type));
    }
    if ($field) {
        push(@query_opts, "lookup.field = ". $self->{"DBH"}->quote(uc($field)));
    }
    if (@strings) {
        push(@query_opts, "lookup.value IN (". join(",", map { $self->{"DBH"}->quote($_) } @strings). ")");
    }

    $sql_query  = "SELECT ";
    $sql_query .= "datastore.id AS id, ";
    $sql_query .= "datastore.type AS type, ";
    $sql_query .= "datastore.serialized AS serialized ";
    $sql_query .= "FROM datastore ";
    $sql_query .= "LEFT JOIN lookup ON lookup.object_id = datastore.id ";
    if (@query_opts) {
        $sql_query .= "WHERE ". join(" AND ", @query_opts) ." ";
    }
    $sql_query .= "GROUP BY datastore.id";

    dprint("$sql_query\n");

    my $sth = $self->{"DBH"}->prepare($sql_query);
    $sth->execute();

    while (my $h = $sth->fetchrow_hashref()) {
        my $id = $h->{"id"};
        my $type = $h->{"type"};
        my $o = Warewulf::DSO->unserialize($h->{"serialized"});
        my $modname = ucfirst($type);
        my $modfile = "Warewulf/$modname.pm";
        if (exists($INC{"$modfile"})) {
            if (ref($o) eq "HASH") {
                &iprint("Working around old datatype format for type: $type\n");
                bless($o, "Warewulf::$modname");
            }
        } else {
            &eprint("Skipping data store object type '$type' (is Warewulf::$modname loaded?)\n");
            next;
        }
        $o->set("_id", $id);
        $o->set("_type", $type);
        $objectSet->add($o);
    }

    return($objectSet);
}


=item get_data($db_id);

=cut

sub
get_data($)
{
    my $self = shift;
    my $db_id = shift;

    my $sql_query;

    $sql_query  = "SELECT ";
    $sql_query .= "datastore.data AS data ";
    $sql_query .= "FROM datastore ";
    $sql_query .= "WHERE datastore.id = ". $self->{"DBH"}->quote($db_id);

    dprint("$sql_query\n\n");

    my $sth = $self->{"DBH"}->prepare($sql_query);
    $sth->execute();

    my $h = $sth->fetchrow_hashref();

    return(exists($h->{"data"}) ? $h->{"data"} : undef);
}


=item set_data($db_id, $data);

=cut

sub
set_data($)
{
    my $self = shift;
    my $db_id = shift;
    my $data = shift;

    if ($db_id) {
        my $sth = $self->{"DBH"}->prepare("UPDATE datastore SET data = ? WHERE id = ?");
        $sth->execute($data, $db_id) or die $self->{"DBH"}->errstr;
    }

    return();
}


=item get_lookups($type, $field, $val1, $val2, $val3);

=cut

sub
get_lookups($$$@)
{
    my $self = shift;
    my $type = shift;
    my $field = shift;
    my @strings = @_;
    my @query_opts;
    my @ret;

    my $sql_query;

    if ($type) {
        push(@query_opts, "datastore.type = ". $self->{"DBH"}->quote($type));
    }
    if ($field) {
        push(@query_opts, "lookup.field = ". $self->{"DBH"}->quote(uc($field)));
    }
    if (@strings) {
        push(@query_opts, "lookup.value IN (". join(",", map { $self->{"DBH"}->quote($_) } @strings). ")");
    }
    push(@query_opts, "lookup.field != 'ID'");

    $sql_query  = "SELECT ";
    $sql_query .= "lookup.value AS value ";
    $sql_query .= "FROM lookup ";
    $sql_query .= "LEFT JOIN datastore ON lookup.object_id = datastore.id ";
    if (@query_opts) {
        $sql_query .= "WHERE ". join(" AND ", @query_opts) ." ";
    }
    $sql_query .= "GROUP BY lookup.value";

    dprint("$sql_query\n\n");

    my $sth = $self->{"DBH"}->prepare($sql_query);
    $sth->execute();

    while (my $h = $sth->fetchrow_hashref()) {
        if (exists($h->{"value"})) {
            push(@ret, $h->{"value"});
        }
    }

    return(@ret);
}


=item persist($objectSet);

=cut

sub
persist($$)
{
    my ($self, @objects) = @_;
    my $event = Warewulf::EventHandler->new();
    my %events;
    my @objlist;

    $event->eventloader();

    foreach my $object (@objects) {
        if (ref($object) eq "Warewulf::ObjectSet") {
            @objlist = $object->get_list();
        } elsif (ref($object) =~ /^Warewulf::/) {
            @objlist = ($object);
        } else {
            &eprint("Invalid object type to persist():  $object\n");
            return undef;
        }
        foreach my $o (@objlist) {
            my $id = $o->get("_id");
            my $type;

            if ($o->can("type")) {
                $type = $o->type();
            } else {
                &cprint("Cannot determine object type!  Is the DSO interface loaded for object class \"". ref($o) ."?\"\n");
                &cprint("Sorry, this error is fatal.  Most likely a problem in $0.\n");
                kill("ABRT", $$);
            }

            if (! $id) {
                my $sth;
                &dprint("Persisting object as new\n");
                $event->handle("$type.new", $o);
                $sth = $self->{"DBH"}->prepare("INSERT INTO datastore (type) VALUES (?)");
                $sth->execute($type);
                $sth = $self->{"DBH"}->prepare("SELECT LAST_INSERT_ID() AS id");
                $sth->execute();
                $id = $sth->fetchrow_array();
                &dprint("Inserted a new object into the datastore (ID: $id)\n");
                $o->set("_id", $id);
            }

            dprint("Updating datastore ID = $id\n");
            $sth = $self->{"DBH"}->prepare("UPDATE datastore SET serialized = ? WHERE id = ?");
            $sth->execute(Warewulf::DSO->serialize($o), $id);

            $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE object_id = ?");
            $sth->execute($id);

            if ($o->can("lookups")) {
                my @add_lookups;
                foreach my $l ($o->lookups) {
                    my @lookups = $o->get($l);
                    if (scalar(@lookups)) {
                        foreach my $value (@lookups) {
                            push(@add_lookups, "(". $self->{"DBH"}->quote(uc($l)) .",". $self->{"DBH"}->quote($value || "UNDEF") .",". $self->{"DBH"}->quote($id) .")");
                        }
                    } else {
                        push(@add_lookups, "(". $self->{"DBH"}->quote(uc($l)) .",'UNDEF',". $self->{"DBH"}->quote($id) .")");
                    }
                }
                &dprint("SQL: INSERT lookup (field, value, object_id) VALUES ". join(",", @add_lookups) ."\n");
                my $sth = $self->{"DBH"}->prepare("INSERT lookup (field, value, object_id) VALUES ". join(",", @add_lookups));
                $sth->execute();
            } else {
                dprint("Not adding lookup entries\n");
            }

            push(@{$events{"$type.modify"}}, $o);
        }
    }
    foreach my $e (keys %events) {
        $event->handle($e, @{$events{"$e"}});
    }
    return(scalar(@objlist));
}




=item del_object($objectSet);

=cut

sub
del_object($$)
{
    my ($self, $object) = @_;
    my $event = Warewulf::EventHandler->new();
    my %events;
    my @objlist;

    if (ref($object) eq "Warewulf::ObjectSet") {
        @objlist = $object->get_list();
    } elsif (ref($object) =~ /^Warewulf::/) {
        @objlist = ($object);
    } else {
        &eprint("Invalid parameter to delete():  $object (". ref($object) .")\n");
        return undef;
    }
    foreach my $o (@objlist) {
        my $id = $o->get("_id");
        my $type = $o->type;

        if ($id) {
            my $sth;
            dprint("Deleting object from the datastore: ID=$id\n");
            $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE object_id = ?");
            $sth->execute($id);
            $sth = $self->{"DBH"}->prepare("DELETE FROM binstore WHERE object_id = ?");
            $sth->execute($id);
            $sth = $self->{"DBH"}->prepare("DELETE FROM datastore WHERE id = ?");
            $sth->execute($id);

            $event->handle("$type.delete", $o);
        }
    }

    return(scalar(@objlist));
}

=item add_lookup($entity, $type, $field, $value)

=cut

sub
add_lookup($$$$)
{
    my $self = shift;
    my $object = shift;
    my $field = shift;
    my $value = shift;

    dprint("Hello from add_lookup()\n");
    if ($object and $type and $field and $value) {
        if (ref($object) eq "Warewulf::ObjectSet") {
            foreach my $o ($object->get_list()) {
                if (my $id = $o->get("_id")) {
                    dprint("Adding a lookup entry for: $field and $value and $id\n");
                    my $sth = $self->{"DBH"}->prepare("INSERT IGNORE lookup (field, value, object_id) VALUES (?,?,?)");
                    $sth->execute(uc($field), $value, $id);
                } else {
                    &wprint("No ID found for object!\n");
                }
            }
        } elsif (ref($object) =~ /^Warewulf::/) {
            if (my $id = $object->get("_id")) {
                dprint("Adding a lookup entry for: $field and $value and $id\n");
                my $sth = $self->{"DBH"}->prepare("INSERT IGNORE lookup (field, value, object_id) VALUES (?,?,?)");
                $sth->execute(uc($field), $value, $id);
            } else {
                &wprint("No ID found for object!\n");
            }
        }
    }

    return();
}

=item del_lookup($entity [$type, $field, $value])

=cut

sub
del_lookup($$$$)
{
    my $self = shift;
    my $object = shift;
    my $type = shift;
    my $field = shift;
    my $value = shift;

    if (ref($object) eq "Warewulf::ObjectSet") {
        foreach my $o ($object->get_list()) {
            my $id = $o->get("_id");
            if ($id and $type and $field and $value) {
                my $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE type = ? AND field = ? AND value = ? AND object_id = ?");
                $sth->execute($type, $field, $value, $id);
            } elsif ($id and $type and $field) {
                my $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE type = ? AND field = ? AND object_id = ?");
                $sth->execute($type, $field, $id);
            } elsif ($id and $type) {
                my $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE type = ? AND object_id = ?");
                $sth->execute($type, $id);
            } elsif ($id) {
                my $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE object_id = ?");
                $sth->execute($id);
            } else {
                &wprint("No ID found for object!\n");
            }
        }
    } elsif (ref($object) =~ /^Warewulf::/) {
        my $id = $object->get("_id");
        if ($id and $type and $field and $value) {
            my $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE type = ? AND field = ? AND value = ? AND object_id = ?");
            $sth->execute($type, $field, $value, $id);
        } elsif ($id and $type and $field) {
            my $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE type = ? AND field = ? AND object_id = ?");
            $sth->execute($type, $field, $id);
        } elsif ($id and $type) {
            my $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE type = ? AND object_id = ?");
            $sth->execute($type, $id);
        } elsif ($id) {
            my $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE object_id = ?");
            $sth->execute($id);
        } else {
            &wprint("No ID found for object!\n");
        }
    }

    return();
}


=item create_entity();

Create a new entity

=cut

sub
new_object($)
{
    my $self = shift;
    my $event = Warewulf::EventHandler->new();
    my $sth;

    wprint("DB->new_object() is deprecated...\n");
    return;


    my $object = Warewulf::Object->new();

    $sth = $self->{"DBH"}->prepare("INSERT INTO datastore (serialized) VALUES ('')");
    $sth->execute();

    $sth = $self->{"DBH"}->prepare("SELECT LAST_INSERT_ID() AS id");
    $sth->execute();

    $object->set("_id", $sth->fetchrow_array());

    return($object);
}



=item binstore($object_id);

Return a binstore object for the given object ID. The binstore object can have
data put or gotten (put_chunk or get_chunk methods respectively) from this
object.

=cut

sub
binstore()
{
    my ($self, $object_id) = @_;
    my $class = ref($self);
    my $dsh = {};

    $dsh->{"DBH"} = $self->{"DBH"};
    $dsh->{"OBJECT_ID"} = $self->{"DBH"}->quote($object_id);
    $dsh->{"BINSTORE"} = 1;

    bless($dsh, $class);

    return($dsh);
}

=item put_chunk($buffer);

Put data into the binstore object one chunk at a time. Iterate through the
entire datastream until all data has been added.

=cut

sub
put_chunk()
{
    my ($self, $buffer) = @_;

    if (! exists($self->{"BINSTORE"})) {
        &eprint("Wrong object type\n");
    }

    if (! exists($self->{"OBJECT_ID"})) {
        &eprint("Can not store into binstore without an object ID\n");
        return;
    }

    if (! exists($self->{"PUT_STH"})) {
        my $sth = $self->{"DBH"}->do("DELETE FROM binstore WHERE object_id = ". $self->{"OBJECT_ID"});
        $self->{"PUT_STH"} = $self->{"DBH"}->prepare("INSERT INTO binstore (object_id, chunk) VALUES (". $self->{"OBJECT_ID"} .",?)");
        &dprint("SQL: INSERT INTO binstore (object_id, chunk) VALUES (". $self->{"OBJECT_ID"} .",?)\n");
    }

    if (! $self->{"PUT_STH"}->execute($buffer)) {
        &eprint("put_chunk() failed with error: ". $self->{"PUT_STH"}->errstr ."\n");
        return();
    } else {
        return(1);
    }
}


=item get_chunk();

Get all of the data out of the binstore object one chunk at a time.

=cut

sub
get_chunk()
{
    my ($self) = @_;

    if (! exists($self->{"BINSTORE"})) {
        &eprint("Wrong object type\n");
    }

    if (! exists($self->{"OBJECT_ID"})) {
        &eprint("Can not store into binstore without an object ID\n");
        return;
    }

    if (! exists($self->{"GET_STH"})) {
        &dprint("SQL: SELECT chunk FROM binstore WHERE object_id = ". $self->{"OBJECT_ID"} ." ORDER BY id\n");
        $self->{"GET_STH"} = $self->{"DBH"}->prepare("SELECT chunk FROM binstore WHERE object_id = ". $self->{"OBJECT_ID"} ." ORDER BY id");
        $self->{"GET_STH"}->execute();
    }

    return($self->{"GET_STH"}->fetchrow_array());
}



=back

=head1 SEE ALSO

Warewulf::ObjectSet Warewulf::DataStore

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;

