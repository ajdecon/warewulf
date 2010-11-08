# Copyright (c) 2003-2010, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# The GNU GPL Document can be found at:
# http://www.gnu.org/copyleft/gpl.html
#
# $Id: Node.pm 50 2010-11-02 01:15:57Z mej $
#

package Warewulf::NodeSet;

use Warewulf::Include;
use Warewulf::Object;
use Warewulf::DBQuery;
use Warewulf::DB;
use Warewulf::ObjectSet;

=head1 NAME

Warewulf::NodeSet - Warewulf's NodeSet interface

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::NodeSet;

    my $obj = Warewulf::NodeSet->new();


=head1 METHODS

=over 12
=cut


=item new()

The new constructor will create the object that references configuration the
stores.

=cut
sub
new($$)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = ();

    $self = {};

    $self->{"DB"} = Warewulf::DB->new();

    bless($self, $class);
    return $self;
}


=item getby_name(@strings)


=cut
sub
getby_name(@)
{
    my $self = shift;
    my $query = Warewulf::DBQuery->new("get");
    $query->table("nodes");
    foreach my $arg (@_) {
        if (ref($arg) eq "ARRAY") {
            $query->match("name", "IN", $arg);
        } elsif ($arg) {
            $query->match("name", "=", $arg);
        } else {
            $query->match("name", "IS", "NULL");
        }
    }

    return(Warewulf::ObjectSet->new($self->{"DB"}->query($query)));
}



=item getby_nodename(@strings)


=cut
sub
getby_nodename(@)
{
    my $self = shift;
    my $query = Warewulf::DBQuery->new("get");
    $query->table("nodes");
    foreach my $arg (@_) {
        if (ref($arg) eq "ARRAY") {
            $query->match("nodename", "IN", $arg);
        } else {
            $query->match("nodename", "=", $arg);
        }
    }

    return(Warewulf::ObjectSet->new($self->{"DB"}->query($query)));
}


=item getby_nodeid(@strings)


=cut
sub
getby_nodeid(@)
{
    my $self = shift;
    my $query = Warewulf::DBQuery->new("get");
    $query->table("nodes");
    foreach my $arg (@_) {
        if (ref($arg) eq "ARRAY") {
            $query->match("id", "IN", $arg);
        } else {
            $query->match("id", "=", $arg);
        }
    }

    return(Warewulf::ObjectSet->new($self->{"DB"}->query($query)));
}


=item getby_vnfs(@strings)


=cut
sub
getby_vnfs(@)
{
    my $self = shift;
    my $query = Warewulf::DBQuery->new("get");
    $query->table("nodes");
    foreach my $arg (@_) {
        if (ref($arg) eq "ARRAY") {
            $query->match("vnfs", "IN", $arg);
        } else {
            $query->match("vnfs", "=", $arg);
        }
    }

    return(Warewulf::ObjectSet->new($self->{"DB"}->query($query)));
}


=item getby_cluster(@strings)


=cut
sub
getby_cluster(@)
{
    my $self = shift;
    my $query = Warewulf::DBQuery->new("get");
    $query->table("nodes");
    foreach my $arg (@_) {
        if (ref($arg) eq "ARRAY") {
            $query->match("cluster", "IN", $arg);
        } else {
            $query->match("cluster", "=", $arg);
        }
    }

    return(Warewulf::ObjectSet->new($self->{"DB"}->query($query)));
}


=item getby_rack(@strings)


=cut
sub
getby_rack(@)
{
    my $self = shift;
    my $query = Warewulf::DBQuery->new("get");
    $query->table("nodes");
    foreach my $arg (@_) {
        if (ref($arg) eq "ARRAY") {
            $query->match("rack", "IN", $arg);
        } else {
            $query->match("rack", "=", $arg);
        }
    }

    return(Warewulf::ObjectSet->new($self->{"DB"}->query($query)));
}


=item getby_group(@groupnames)


=cut
sub
getby_groupname(@)
{
    my $self = shift;
    my @nodeids;
    my $query = Warewulf::DBQuery->new("get");
    $query->table("groups");
    foreach my $arg (@_) {
        if (ref($arg) eq "ARRAY") {
            $query->match("name", "IN", $arg);
        } else {
            $query->match("name", "=", $arg);
        }
    }
    my $groupSet = Warewulf::ObjectSet->new($self->{"DB"}->query($query));

    foreach my $nodeid ($groupSet->get_list_entries("nodeids")) {
        push(@nodeids, split(/,/, $nodeid));
    }

    return($self->getby_nodeid(\@nodeids));
}



=back

=head1 SEE ALSO

Warewulf::Node, Warewulf::ObjectSet, Warewulf::Object

=head1 COPYRIGHT

Warewulf is copyright UC Regents

=cut


1;
