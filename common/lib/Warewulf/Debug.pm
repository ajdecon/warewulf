# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::Debug;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = ('&backtrace');

=head1 NAME

Warewulf::Debug - Debugging functions

=head1 ABOUT

The Warewulf::Debug provides debugging functions

=head1 SYNOPSIS

    use Warewulf::Debug;


=item backtrace()

Throw a backtrace at the current location in the code.

=cut
sub
backtrace()
{
    my $file             = ();
    my $line             = ();
    my $subroutine       = ();
    my $i                = ();
    my @tmp              = ();

    print STDERR "STACK TRACE:\n";
    print STDERR "------------\n";
    for ($i = 0; @tmp = caller($i); $i++) {
        $subroutine = $tmp[3];
        (undef, $file, $line) = caller($i);
        $file =~ s/^.*\/([^\/]+)$/$1/;
        print STDERR '      ', ' ' x $i, "$subroutine() called at $file:$line\n";
    }
    print STDERR "\n";
}


=head1 SEE ALSO

Warewulf::Logger

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

BEGIN {
    $SIG{"__WARN__"} = sub { warn @_; &backtrace(); };
    $SIG{"__DIE__"} = sub { &backtrace(); die @_; }; 
}

1;
