# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: DSOFactory.pm 83 2010-12-09 22:13:21Z gmk $
#

package Warewulf::DSOFactory;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::DSO;
use DBI;

my %modules;

=head1 NAME

Warewulf::DSOFactory - This will automatically load the appropriate DSO
(Data Store Object) on an as needed basis.

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::DSOFactory;

    my $obj = Warewulf::DSOFactory->new($type);

=item new()

Create the object.

=cut
sub
new($$)
{
    my $proto = shift;
    my $type = uc(shift);
    my $obj;

    if ( $type =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        $type = $1;

        my $mod_name = "Warewulf::DSO::". ucfirst(lc($type));

        if (! exists($modules{$mod_name})) {
            &dprint("Loading object name: $mod_name\n");
            eval "\$SIG{__DIE__} = sub { 1; }; require $mod_name;";
            if ($@) {
                &iprint("Could not load DataStore object class for type '$type', loading a DSO baseclass instead!\n");
                my $obj = Warewulf::DSO->new(@_);
                $obj->set("type", $type);
                return($obj);
            }
            $modules{$mod_name} = 1;
        }

        &dprint("Getting a new object from $mod_name\n");

        $obj = eval "$mod_name->new(\@_)";

        &dprint("Got an object: $obj\n");
    } elsif ($type) {
        &eprint("Illegal character in mod_name type: $type\n");
    } else {
        &eprint("DSOFactory called without type!\n");
        $obj = Warewulf::DSO->new(@_);
        $obj->set("type", "UNDEFINED");
    }

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

