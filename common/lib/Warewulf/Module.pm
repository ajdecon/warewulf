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
# $Id: Module.pm 99 2010-12-15 08:47:10Z mej $
#

package Warewulf::Module;

use Warewulf::Include;
use Warewulf::Logger;

our @ISA = ();

=head1 NAME

Warewulf::Module - 

=head1 SYNOPSIS

    use Warewulf::Module;

=head1 DESCRIPTION

    Mooooo

=head1 METHODS

=over 4

=item keyword()

Defines this module's keyword. By default this will be the lowercase
name of the module suffix (e.g. Warewulf::Module::Foo will return the
keyword or 'foo').

=cut
sub
keyword()
{
    my $self = shift;
    my $keyword = ref($self);
    $keyword =~ s/^.+:://;

    return(lc($keyword));
}

=item usage()

Define the command line usage of this module interface.

=cut
sub
usage()
{
    my $self = shift;
    dprint("Module method undefined: ". ref($self) ."->usage()\n");
}



1;
