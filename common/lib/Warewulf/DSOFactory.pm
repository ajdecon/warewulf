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

my %classes;


BEGIN {
    foreach my $path (@INC) {
        foreach my $req (glob("$path/Warewulf/DSO/*.pm")) {
            if ($req =~ /^([a-zA-Z0-9\/\._\-]+?\/Warewulf\/DSO\/([a-zA-Z0-9\-_]+)\.pm)$/) {
                my $file = $1;
                my $baseclass = $2;
                my $class = "Warewulf::DSO::$baseclass";
                my $name = uc($baseclass);

                eval {
                    require $file;
                };

                if ($class->can("new")) {
                    print "Making $class accessible by name '$name'\n";
                    $classes{"$name"} = $class;
                }

            }

        }
    }

}

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
    my $type = shift;
    my $obj;

    if ( $type =~ /^([a-zA-Z0-9\-_\.]+)$/ ) {
        my $name = uc($1);

        if (exists($classes{"$name"})) {
            $obj = $classes{"$name"}->new(@_);
        } else {
            &iprint("Could not load DataStore object class for type '$name', loading a DSO baseclass instead!\n");
            $obj = Warewulf::DSO->new(@_);
        }

        &dprint("Got an object: $obj\n");
    } elsif ($type) {
        &eprint("Illegal character in mod_name type: $type\n");
    } else {
        &eprint("DSOFactory called without type!\n");
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

