# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
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

                if (exists($classes{"$name"})) {
                    # Already loaded
                } else {
                    eval {
                        no warnings;
                        local $SIG{__WARN__} = sub { 1; };
                        require $file;
                    };

                    if ($class->can("new")) {
                        $classes{"$name"} = $class;
                    }
                }

            }

        }
    }

}

=head1 NAME

Warewulf::DSOFactory - Instantiate Data Store Objects (DSOs)

=head1 SYNOPSIS

    use Warewulf::DSOFactory;

    my $foo = Warewulf::DSOFactory->new("foo");

=head1 DESCRIPTION

This factory object instantiates the requested Data Store Object (DSO)
by name and returns a reference to the instance created.

=head1 METHODS

=over 4

=item new(type)

The new() method will return an instance of the specified DSO type.
All available DSO class files are dynamically loaded at runtime, and
the desired type is specified by its basename.  For example, specify
"node" to create an instance of a Warewulf::DSO::Node object.

=cut

sub
new($$)
{
    my $proto = shift;
    my $type = shift;
    my $obj;

    if ($type =~ /^([a-zA-Z0-9\-_\.]+)$/) {
        my $name = uc($1);

        if (exists($classes{"$name"})) {
            $obj = $classes{"$name"}->new(@_);
        } else {
            &iprint("DSO type \"$type\" does not exist, instantiating DSO base class instead!\n");
            $obj = Warewulf::DSO->new(@_);
        }
        &dprint("Got an object:  $obj\n");
    } elsif ($type) {
        &eprint("Illegal character in object type:  $type\n");
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

