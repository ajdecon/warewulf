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


#use Exporter;
#
#
#our @ISA = ('Exporter');
#
#our @EXPORT = qw(
#    &wwmod_register
#    &wwmod_run
#    &wwmod_init
#);
#
#my %modules;
#
##sub
#wwmod_init()
#{
#    %modules = ();
#    my $libexec = &wwpath("libexecdir") ."/warewulf/modules";
#
#    if (!exists($self->{"MODULES"})) {
#        foreach my $file (glob("$libexec/*.pm"), glob("$ENV{WWMODPATH}/*.pm")) {
#            my ($name, $tmp, $keyword);
#            dprint("Module load file: $file\n");
#
#            eval "require '$file'";
#        }
#    }
#}
#
#sub
#wwmod_register($$$)
#{
#    my $type = shift;
#    my $trigger = shift;
#    my $func = shift;
#    my ($package, $filename, $line) = caller;
#
#    dprint("Module register: TYPE=$type, TRIGGER=$trigger, FUNC=$func\n");
#
#    if ($func) {
#        push(@{$modules{$type}{$trigger}}, $package->$func);
#    } else {
#        push(@{$modules{$type}{$trigger}}, $package->new());
#    }
#}
#
#
#sub
#wwmod_run($$@)
#{
#    my $type = shift;
#    my $trigger = shift;
#    my $method = shift;
#    my @args = @_;
#
#    foreach my $f (&wwmod_list($type, $trigger)) {
#        $f->$method(@args);
#    }
#}
#
#sub
#wwmod_list($$)
#{
#    my $type = shift;
#    my $trigger = shift;
#
#    if (exists($modules{$type}) and exists($modules{$type}{$trigger})) {
#        return@{$modules{$type}{$trigger}});
#    }
#
#    return();
#}


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
    my $libexec = &wwpath("libexecdir") ."/warewulf/modules";
    my $self = {};

    bless($self, $class);

    if (!exists($self->{"MODULES"})) {
        foreach my $file (glob("$libexec/$type/*.pm"), glob("$ENV{WWMODPATH}/$type/*.pm")) {
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
            if ($obj->keyword() eq $keyword) {
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

