# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::DataStore;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::Config;
use Warewulf::DataStore::SQL;
use DBI;

=head1 NAME

Warewulf::DataStore - Interface to backend data store

=head1 SYNOPSIS

    use Warewulf::DataStore;

    print "Creating DataStore interface object\n";
    my $ds = Warewulf::DataStore->new();
    my $entity = $ds->new_object();

    print "Setting some stuff\n";
    $entity->set("name", "gmk00");

    print "Persisting object\n";
    $ds->persist($entity);

    print "Adding lookups\n";
    $ds->add_lookup($entity, "node", "name", "gmk00");
    $ds->add_lookup($entity, "node", "status", "READY");

    print "Getting stuff\n";
    my $objectSet = $ds->get_objects("node", "name", "gmk00");
    foreach my $o ($objectSet->get_list()) {
        print "name: ". $o->get("name") ."\n";
    }

=head1 DESCRIPTION

Warewulf uses an abstract data store to persist and retrieve the
objects it uses to represent the various components of the systems it
manages.  This class represents an instance of that data store, and
its methods are used to store and retrieve objects as well as specify
how those objects may be identified uniquely within the data store.

=head1 METHODS

=over 4

=item new()

Create the object that will act as the interface to the data store.
The specific data store implementation to be used is determined by
configuration ("database type" in C<database.conf>).

=cut

sub
new($$)
{
    my $proto = shift;
    my $config = Warewulf::Config->new("database.conf");
    my $ds_engine = $config->get("database type") || "sql";

    if ($ds_engine eq "sql") {
        return(Warewulf::DataStore::SQL->new(@_));
    } else {
        &eprint("Could not load DS type \"$ds_engine\"\n");
        exit 1;
    }

    return();
}

=item get_objects($type, $field, $match_string_1, [...])

Return a Warewulf::ObjectSet that includes all of the matched Warewulf::Object
instances for the given criteria.

=cut

sub
get_objects()
{
    return undef;
}

=item new_object()

Return a single Warewulf::Object. This is a necessary step if you wish for the
objects that you are dealing with to be persisted because this will reserve a
place in the DataStore for the empty Object.

=cut

sub
new_object()
{
    return undef;
}

=item persist($object)

Persist an Object (or group of Objects in an ObjectSet) to the
DataStore. By default, if they exist, certain fields within each
Object will automatically generate lookup entries as well.

=cut

sub
persist($)
{
    return undef;
}

=item add_lookup($object, $type, $field, $value)

Add a lookup entry to the DataStore for the specified object.  Queries
for objects of type $type whose $field value is $value will return
$object.

=cut

sub
add_lookup($$$$)
{
    return undef;
}

=item del_lookup($object, [$type, [$field, [$value]]])

This will delete lookup entries. The Object is required, but the other
arguments are optional. Any arguments not supplied will not be used to
determine which lookup(s) are deleted. The more arguments you supply,
the finer the granularity with which you can specify what to
remove. If only the object instance is supplied, all lookups for that
object will be removed.

=cut

sub
del_lookup()
{
    return undef;
}

=back

=head1 SEE ALSO

Warewulf::Object, Warewulf::ObjectSet

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;

