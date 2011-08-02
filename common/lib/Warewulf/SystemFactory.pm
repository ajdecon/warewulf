# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: SystemFactory.pm 83 2010-12-09 22:13:21Z gmk $
#

package Warewulf::SystemFactory;

use Warewulf::Util;
use Warewulf::Logger;
use DBI;

my %modules;

=head1 NAME

Warewulf::SystemFactory - Factory class for Warewulf::System objects

=head1 SYNOPSIS

    use Warewulf::SystemFactory;

    my $sys = Warewulf::SystemFactory->new($type);

=head1 DESCRIPTION

This class is a factory for Warewulf::System objects.

=head1 METHODS

=over 4

=item new()

Create and return a System instance of the requested type.

=cut

sub
new($$)
{
    my ($proto, $type) = @_;
    my ($mod_name, $obj);

    if (! $type) {
        if (-f "/etc/redhat-release") {
            $type = "rhel";
        }
    }

    $mod_name = "Warewulf::System::" . ucfirst(lc($type));

    if (!exists($modules{$mod_name})) {
        &dprint("Loading object name: $mod_name\n");
        eval "require $mod_name";
        if ($@) {
            &cprint("Could not load '$mod_name'!\n");
            exit 1;
        }
        $modules{$mod_name} = 1;
    }

    &dprint("Getting a new object from $mod_name\n");

    $obj = eval "$mod_name->new(\@_)";

    &dprint("Got an object: $obj\n");

    return $obj;
}

=back

=head1 SEE ALSO

Warewulf::System

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

1;

