# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Event.pm 83 2010-12-09 22:13:21Z gmk $
#

package Warewulf::Event;

use Warewulf::Util;
use Warewulf::Logger;
use File::Basename;

my $singleton;

=head1 NAME

Warewulf::Event - Database interface

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::Event;

    my $obj = Warewulf::Event->new();

=item new()

Create the object.

=cut

sub new() { };


=back

=head1 SEE ALSO

Warewulf::Module

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;

