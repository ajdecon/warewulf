# Copyright (c) 2003-2010, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# The GNU GPL Document can be found at:
# http://www.gnu.org/copyleft/gpl.html
#
# $Id: DB.pm 83 2010-12-09 22:13:21Z gmk $
#

package Warewulf::ModuleLoader;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::Config;
use Warewulf::Include;
use File::Basename;

my %modules;

BEGIN {
}

=head1 NAME

Warewulf::ModuleLoader - Database interface

=head1 ABOUT


=head1 SYNOPSIS

    use Warewulf::ModuleLoader;

    my $obj = Warewulf::ModuleLoader->new($type);

=item new()

Create the object.

=cut

sub
new($)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $libexec = &wwpath("libexecdir") ."/warewulf/modules";
    my $self = {};

    bless($self, $class);


    if (!exists($self->{"MODULES"})) {
        foreach my $file (glob("$libexec/*.pm"), glob("$ENV{WWMODPATH}/*.pm")) {
            my ($name, $tmp, $keyword);

            dprint("Module load file: $file\n");
            eval "require '$file'";

            $name = "Warewulf::Module::". basename($file);
            $name =~ s/\.pm$//;

            $tmp = eval "$name->new()";
            if ($tmp) {
                push @{$self->{"MODULES"}}, $tmp;
            } else {
                dprint("Module load error: Could not invoke $name->new()\n");
            }
        }
    }

    return($self);
}

=item list($type, $key)


=cut
sub
list($$)
{
    my $self = shift;
    my $type = shift;
    my $key = shift;
    my @ret;

    if ($type and $key)
        foreach my $obj (@{$self->{"MODULES"}}) {
            if ($obj->type($type) and $obj->key($key)) {
                push(@ret, $obj);
            }
        }
    } elsif ($type) {
        foreach my $obj (@{$self->{"MODULES"}}) {
            if ($obj->type($type)) {
                push(@ret, $obj);
            }
        }
    } else {
        foreach my $obj (@{$self->{"MODULES"}}) {
            push(@ret, $obj);
        }
    }

    return(@ret);
}




=back

=head1 SEE ALSO

Warewulf::Module

=head1 COPYRIGHT

Copyright (c) 2003-2010, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

The GNU GPL Document can be found at:
http://www.gnu.org/copyleft/gpl.html

=cut



1;

