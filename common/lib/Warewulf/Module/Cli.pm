# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
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

=item options()

Define the command line options of this module interface.

=cut

#sub options() { };


=item description()

Verbose description of the module

=cut

#sub description() { };


=item summary()

A very short summary describing this module

=cut

#sub summary() { };


=item examples()

Return an array of usage examples

=cut

#sub examples() { };


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
