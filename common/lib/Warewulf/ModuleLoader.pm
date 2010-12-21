# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id: ModuleLoader.pm 83 2010-12-09 22:13:21Z gmk $
#

package Warewulf::ModuleLoader;

use Warewulf::Util;
use Warewulf::Logger;
use Warewulf::Config;
use Warewulf::Include;
use File::Basename;


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
    my $type = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    bless($self, $class);

    if (!exists($self->{"MODULES"})) {
        foreach my $path (@INC, $ENV{WWMODPATH}) {
            dprint("Module load path: $path\n");
            foreach my $file (glob("$path/Warewulf/Module/$type/*.pm")) {
                my ($name, $tmp, $keyword);

                dprint("Module load file: $file\n");
                eval "require '$file'";

                $name = "Warewulf::Module::". $type ."::". basename($file);
                $name =~ s/\.pm$//;


                $tmp = eval "$name->new()";
                if ($tmp) {
                    push(@{$self->{"MODULES"}}, $tmp);
                    dprint("Module load success: Added module $name\n");
                } else {
                    dprint("Module load error: Could not invoke $name->new()\n");
                }
            }
        }
    }

    return($self);
}

=item list($keyword)


=cut
sub
list($$)
{
    my $self = shift;
    my $keyword = shift;
    my @ret;

    if ($keyword) {
        dprint("Module list: looking for keyword: $keyword\n");
        foreach my $obj (@{$self->{"MODULES"}}) {
            if ($obj->keyword($keyword)) {
                dprint("Found object: $obj\n");
                push(@ret, $obj);
            }
        }
    } else {
        dprint("Returning all modules\n");
        @ret = @{$self->{"MODULES"}};
    }

    return(@ret);
}



=back

=head1 SEE ALSO

Warewulf::Module

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut


1;

