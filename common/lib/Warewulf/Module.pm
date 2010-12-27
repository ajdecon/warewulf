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

use Warewulf::Object;
use Warewulf::Logger;

our @ISA = ('Warewulf::Object');


=head1 NAME

Warewulf::Module - 

=head1 SYNOPSIS

    use Warewulf::Module;

=head1 DESCRIPTION

    Mooooo

=head1 METHODS

=over 4

=item keyword($test)

Tests for the module applicability based on keyword. If the passed in
keyword is good for that module, then this will return true. By default
a keyword is the lowercase name of the module's suffix (e.g.
Warewulf::Module::Foo will be true for a test of "foo".

Each module can redefine this method such that it can be true for any
number of passed in keywords. In the end, the module itself needs to
know its features and abilities.

=cut
sub
keyword()
{
    my $self = shift;
    my $test = shift;
    my $keyword = ref($self);
    $keyword =~ s/^.+:://;

    if (lc($keyword) eq lc($test)) {
        return(1);
    }

    return();
}

=item init()

Initialization when this module gets called

=cut
sub init() { };


=item datastore()

Pass the datastore module into the Module object and be able to retrieve it
easily.

=cut
sub
datastore()
{
    my $self = shift;
    my $datastore = shift;

    if ($datastore) {
        &dprint("Setting datastore for: ". ref($self) .": $datastore\n");
        $self->{"datastore"} = $datastore;
    }

    return($self->{"datastore"});
}


=head1 SEE ALSO

Warewulf::Module::Cli, Warewulf::Module::Trigger

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;
