# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::DB;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::Config;
use Warewulf::DB::SQL;
use DBI;


=head1 NAME

Warewulf::DB - Database interface

=head1 ABOUT

The Warewulf::DB interface simplies typically used DB calls and operates on
Warewulf::Objects and Warewulf::ObjectSets for simplistically integrating
with native Warewulf code.

=head1 SYNOPSIS

    use Warewulf::DB;

    print "creating new object\n";
    my $db = Warewulf::DB::SQL::MySQL->new();
    my $entity = $db->new_object();

    print "Setting some stuffs\n";
    $entity->set("name", "gmk00");

    print "persisting\n";
    $db->persist($entity);

    print "adding lookups\n";
    $db->add_lookup($entity, "node", "name", "gmk00");
    $db->add_lookup($entity, "node", "status", "READY");

    print "Getting stuffs\n";

    my $objectSet = $db->get_objects("node", "name", "gmk00");
    foreach my $o ( $objectSet->get_list() ) {
        print "name: ". $o->get("name") ."\n";
    }


=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto = shift;
    my $config = Warewulf::Config->new("database.conf");
    my $db_engine = $config->get("database type") || "sql";

    if ($db_engine eq "sql") {
        return(Warewulf::DB::SQL->new(@_));
    } else {
        &eprint("Could not load DB type: $db_engine\n");
        exit 1;
    }

    return();
}

=item get_objects($type, $field, @sstrings_to_match)

Return a Warewulf::ObjectSet that includes all of the matched Warewulf::Objects
for the given criteria.

=item new_object()

Return a single Warewulf::Object. This is a necessary step if you wish for the
objects that you are dealing with to be persisted because this will reserve a
place in the DataStore for this empty Object.

=item persist($entity)

This will persist an ObjectSet or a single Object to the DataStore. By default
certain fields if they exist within each Object will automatically create
lookup entries if that is needed for the DataStore backend you are using.

=item add_lookup($entity, $type, $field, $value)


=item del_lookup($entity [, $type, $field, $value])

This will delete lookup entities. The Object entitiy is required, but the
other arguments are optional. If they are not passed, then they will not
be used in the comparasion on if that lookup is deleted. Thus the more
arguments you have (left to right), the finer granularity you can remove.

=back

=head1 SEE ALSO

Warewulf::Object Warewulf::ObjectSet

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut




1;

