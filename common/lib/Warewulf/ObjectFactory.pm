# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: ObjectFactory.pm 83 2010-12-09 22:13:21Z gmk $
#

package Warewulf::ObjectFactory;

use Warewulf::Util;
use Warewulf::Logger;
use DBI;

my %modules;

=head1 NAME

Warewulf::ObjectFactory - 

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::ObjectFactory;

    my $obj = Warewulf::ObjectFactory->new($type);

=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto = shift;
    my $type = uc(shift);
    my $mod_name = "Warewulf::". ucfirst(lc($type));

    if (! exists($modules{$mod_name})) {
        &dprint("Loading object name: $mod_name\n");
        eval "require $mod_name";
        if ($@) {
            &cprint("Could not load '$mod_name'!\n");
            exit 1;
        }
        $modules{$mod_name} = 1;
    }

    &dprint("Getting a new object from $mod_name\n");

    my $obj = eval "$mod_name->new(\@_)";

    &dprint("Got an object: $obj\n");

    return($obj);
}

=back

=head1 SEE ALSO

Warewulf::Object, Warewulf::ObjectSet

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut

1;

