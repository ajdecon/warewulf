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

package Warewulf::Module::Cli;

use Warewulf::Include;
use Warewulf::Logger;
use Warewulf::Module;

our @ISA = ('Warewulf::Module');


=head1 NAME

Warewulf::Module::Cli - 

=head1 SYNOPSIS

    use Warewulf::Module::Cli;

=head1 DESCRIPTION

    Mooooo

=head1 METHODS

=over 4

=item usage()

Define the command line usage of this module interface.

=cut
sub usage() { };


=item call()

What happens when this module gets called

=cut
sub call() {};


1;
