# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: MySQL.pm 62 2010-11-11 16:01:03Z gmk $
#

package Warewulf::DB::SQL::MySQL;

use Warewulf::Config;
use Warewulf::DB;
use Warewulf::Logger;
use Warewulf::Object;
use Warewulf::ObjectFactory;
use Warewulf::ObjectSet;
use DBI;
use Storable qw(freeze thaw);

# Declare the singleton
my $singleton;

=head1 NAME

Warewulf::DB::SQL::MySQL - MySQL Database interface to Warewulf

=head1 SYNOPSIS

    use Warewulf::DB::SQL::MySQL;

=head1 DESCRIPTION

    This class should not be instantiated directly.  It is intended to be
    treated as an opaque implementation of the DB interface.

    This class creates a persistant singleton for the application runtime
    which will maintain a consistant database connection from the time that
    the object is constructed.
    
    Documentation for each function should be found in the top level
    Warewulf::DB documentation. Any implementation specific documentation
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
    my $config = Warewulf::Config->new("database.conf");
    my $db_server = $config->get("database server");
    my $db_name = $config->get("database name");
    my $db_user = $config->get("database user");
    my $db_pass = $config->get("database password");
 
    if ($singleton && exists($singleton->{"DBH"}) && $singleton->{"DBH"}) {
        &dprint("DB Singleton exists, not going to initialize\n");
    } else {
        %{$singleton} = ();

        if ($db_name and $db_server and $db_user) {
            &dprint("DATABASE NAME:      $db_name\n");
            &dprint("DATABASE SERVER:    $db_server\n");
            &dprint("DATABASE USER:      $db_user\n");

            $singleton->{"DBH"} = DBI->connect("DBI:mysql:database=$db_name;host=$db_server", $db_user, $db_pass);
            if ( $singleton->{"DBH"}) {
                &iprint("Successfully connected to database!\n");
            } else {
                die "Could not connect to DB: $!!\n";
            }

            bless($singleton, $class);
        } else {
            &eprint("Undefined credentials for database\n");
        }
    }

    return $singleton;
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

    dprint("$sql_query\n\n");

    my $sth = $self->{"DBH"}->prepare($sql_query);
    $sth->execute();

    while (my $h = $sth->fetchrow_hashref()) {
        my $id = $h->{"id"};
        my $type = $h->{"type"};
#        dprint("Adding to ObjectSet object ID: $id\n");
        my $o = Warewulf::ObjectFactory->new($type, $self->unserialize($h->{"serialized"}));
        $o->set("id", $id);
        $o->set("type", $type);
        $objectSet->add($o);
    }

    return($objectSet);
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
    my ($self, $object) = @_;
    my @objlist;

    if (ref($object) eq "Warewulf::ObjectSet") {
        @objlist = $object->get_list();
    } elsif (ref($object) =~ /^Warewulf::Object::/) {
        @objlist = ($object);
    } else {
        &eprint("Invalid parameter to persist():  $object\n");
        return undef;
    }
    foreach my $o (@objlist) {
        my $id = $o->get("id");

        if (! $id) {
            my $sth;
            dprint("Inserting a new object into the datastore\n");
            $sth = $self->{"DBH"}->prepare("INSERT INTO datastore (type) VALUES (?)");
            $sth->execute($o->type());
            $sth = $self->{"DBH"}->prepare("SELECT LAST_INSERT_ID() AS id");
            $sth->execute();
            $id = $sth->fetchrow_array();
            $o->set("id", $id);
        }

        dprint("Updating datastore ID = $id\n");
        $sth = $self->{"DBH"}->prepare("UPDATE datastore SET serialized = ? WHERE id = ?");
        $sth->execute($self->serialize(scalar($o->get_hash())), $id);

        $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE object_id = ?");
        $sth->execute($id);

        if ($o->can("lookups")) {
            my @add_lookups;
            foreach my $l ($o->lookups) {
                foreach my $value ($o->get($l)) {
                    push(@add_lookups, "(". $self->{"DBH"}->quote(uc($l)) .",". $self->{"DBH"}->quote($value || "[undef]") .",". $self->{"DBH"}->quote($id) .")");
                }
            }
            my $sth = $self->{"DBH"}->prepare("INSERT lookup (field, value, object_id) VALUES ". join(",", @add_lookups));
            $sth->execute();
        } else {
            dprint("Not adding lookup entries\n");
        }
    }
    return(scalar(@objlist));
}




=item del_object($objectSet);

=cut

sub
del_object($$)
{
    my ($self, $object) = @_;
    my @objlist;

    if (ref($object) eq "Warewulf::ObjectSet") {
        @objlist = $object->get_list();
    } elsif (ref($object) =~ /^Warewulf::Object::/) {
        @objlist = ($object);
    } else {
        &eprint("Invalid parameter to persist():  $object\n");
        return undef;
    }
    foreach my $o (@objlist) {
        my $id = $o->get("id");

        if ($id) {
            my $sth;
            dprint("Deleting object from the datastore: ID=$id\n");
            $sth = $self->{"DBH"}->prepare("DELETE FROM lookup WHERE object_id = ?");
            $sth->execute($id);
            $sth = $self->{"DBH"}->prepare("DELETE FROM datastore WHERE id = ?");
            $sth->execute($id);
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
                if (my $id = $o->get("id")) {
                    dprint("Adding a lookup entry for: $field and $value and $id\n");
                    my $sth = $self->{"DBH"}->prepare("INSERT IGNORE lookup (field, value, object_id) VALUES (?,?,?)");
                    $sth->execute(uc($field), $value, $id);
                } else {
                    &wprint("No ID found for object!\n");
                }
            }
        } elsif (ref($object) =~ /^Warewulf::Object::/) {
            if (my $id = $object->get("id")) {
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
            my $id = $o->get("id");
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
    } elsif (ref($object) =~ /^Warewulf::Object::/) {
        my $id = $object->get("id");
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
    my $sth;

    wprint("DB->new_object() is deprecated...\n");
    return;


    my $object = Warewulf::Object->new();

    $sth = $self->{"DBH"}->prepare("INSERT INTO datastore (serialized) VALUES ('')");
    $sth->execute();

    $sth = $self->{"DBH"}->prepare("SELECT LAST_INSERT_ID() AS id");
    $sth->execute();

    $object->set("id", $sth->fetchrow_array());

    return($object);
}


=back

=head1 SEE ALSO

Warewulf::ObjectSet Warewulf::DB

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;

