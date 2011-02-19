# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: System.pm 50 2010-11-02 01:15:57Z gmk $
#

package Warewulf::System;

use Warewulf::Object;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::System - Warewulf's System (Data Store Object) base class

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::System;

    my $obj = Warewulf::System->new();


=head1 METHODS

=over 12
=cut


=item new()

The new constructor will create the object that references configuration the
stores.

=cut
sub new($$) { undef; };



=item service($name, $command)

Run a command on a service script (e.g. /etc/init.d/service restart).

=cut
sub service($$) { undef; };


=item chkconfig($name, $command)

Enable a service script to be enabled or disabled at boot (e.g.
/sbin/chkconfig service on).

=cut
sub chkconfig($$) { undef; };


=item output()

return the output cache on a command

=cut
sub output($$) { undef; };





=back

=head1 SEE ALSO

Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
