# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: DB.pm 51 2010-11-07 03:16:29Z gmk $
#

package Warewulf::DB::SQL;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::Config;
use Warewulf::DB::SQL::MySQL;
use DBI;


=head1 NAME

Warewulf::DB::SQL - Database interface

=head1 ABOUT

The Warewulf::DB::SQL interface simplies typically used DB calls.

=head1 SYNOPSIS

    use Warewulf::DB::SQL;

=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto = shift;
    my $config = Warewulf::Config->new();
    my $db_engine = $config->get("database driver") || "mysql";

    if ($db_engine eq "mysql") {
        return(Warewulf::DB::SQL::MySQL->new(@_));
    } else {
        &eprint("Could not load DB type: $db_engine\n");
        exit 1;
    }

    return();
}

=back

=head1 SEE ALSO

Warewulf::DB

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;

