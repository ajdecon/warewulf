# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Cli.pm 99 2010-12-15 08:47:10Z mej $
#

package Warewulf::Module::Cli;

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


=item help()

Show the help options for this module

=cut
sub help() {};


=item command()

What happens when this module gets called by a command

=cut
sub exec() {};


=item complete()

What to do when this module gets called for autocompletion

=cut
sub complete() {};


=head1 SEE ALSO

Warewulf, Warewulf::Module

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

1;
