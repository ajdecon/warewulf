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
new($$)
{
    my $proto = shift;
    my $keyword = shift;

    if (exists($modules{$keyword})) {
        return($modules{"$keyword"});
    } else {
        eprint("Module keyword '$keyword' is not available\n");
    }

    return();
}

=item load(<class>)

Load all modules of a specified class from the module tree (by
default, /usr/libexec/warewulf/modules/<class>/).

=cut

sub
load($)
{
    my ($self, $class) = @_;
    my $libexec = &wwpath("libexecdir") ."/warewulf/modules";

    if (!exists($self->{"MODULES"}{$class})) {
        foreach my $file (glob("$libexec/$class/*.pm"), glob("$ENV{WWMODPATH}/$class/*.pm")) {
            my ($name, $tmp, $keyword);

            dprint("Module load file: $file\n");
            eval "require '$file'";

            $name = "Warewulf::Module::". basename($file);
            $name =~ s/\.pm$//;

            $tmp = eval "$name->new()";
            if ($tmp) {
                push @{$self->{"MODULES"}{$class}}, $tmp;
            } else {
                dprint("Module load error: Could not invoke $name->new()\n");
            }
        }
    }
    
    return @{$self->{"MODULES"}{$class}};
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

