# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: Module.pm 99 2010-12-15 08:47:10Z mej $
#

package Warewulf::Module;

use Warewulf::Include;
use Warewulf::Logger;


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

=item init()

Initialization when this module gets called

=cut
sub init() { };



=head1 SEE ALSO

Warewulf::Module::Cli, Warewulf::Module::Trigger

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
