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

use Warewulf::Object;

our @ISA = ('Warewulf::Object');

=head1 NAME

Warewulf::Event - Event base class

=head1 SYNOPSIS

    use Warewulf::Event;
    our @ISA = ('Warewulf::Event');

=head1 DESCRIPTION

This class acts as a generic base class for all Warewulf Events.  It
should never be directly instantiated.

=head1 METHODS

=over 4

=item new()

Creates and returns a new Event object.

=cut

sub
new()
{
    my ($proto, @args) = @_;
    my $class = ref($proto) || $proto;
    my $self;

    $self = $class->SUPER::new();
    bless($self, $class);

    return $self->init(@args);
}

=back

=head1 SEE ALSO

Warewulf::EventHandler, Warewulf::Object

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;

