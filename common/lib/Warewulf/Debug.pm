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





1;
