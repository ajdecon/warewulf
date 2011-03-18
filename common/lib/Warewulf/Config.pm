# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#
#
# $Id$
#

package Warewulf::Config;

use Warewulf::Include;
use Warewulf::Debug;
use Warewulf::Logger;
use Warewulf::Util;
use Warewulf::Object;
use Text::ParseWords;

our @ISA = ('Warewulf::Object', 'Exporter');

=head1 NAME

Warewulf::Config - Object interface to configuration paramaters

=head1 ABOUT

The Warewulf::Config class allows one to access configuration paramaters
with as an object interface.

=head1 SYNOPSIS

    use Warewulf::Config;

    my $obj = Warewulf::Config->new("something.conf");

    foreach my $entry ( $obj->get("config entry name") ) {
        print "->$entry<-\n";
    }

=head1 FORMAT

The configuration file format utilizes key value pairs seperated by an
equal ('=') sign. There maybe multiple key value pairs as well as comma
delimated value entries.

Line continuations are allowed as long as the previous line entry ends
with a backslash.

    key value = entry one, entry two, "entry two,a"
    key value = entry three, \
    entry four

Will yield the following values:

    entry one
    entry two
    entry two,a
    entry three
    entry four


=head1 METHODS

=over 12
=cut


=item new($config_name)

The new constructor will create the object that references configuration the
stores. You can pass a list of configuration files that will be included in
the object if desired. Each config will be searched for, first in the users
home/private directory and then in the global locations.

=cut

my %files;

sub
new()
{
    my ($proto, @args) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};

    $self = $class->SUPER::new();
    bless($self, $class);

    return($self->parse(@args));
}

sub
parse()
{
    my ($self, @args) = @_;

    my @basepaths = (
        (getpwuid $>)[7] . "/.warewulf",
        $Warewulf::Include::wwconfig{"SYSCONFDIR"} . "/warewulf"
    );

    foreach my $file (@args) {
        if (exists($files{"$file"})) {
            &iprint("Using cached configuration file: $file\n");
        } else {
            foreach my $path (@basepaths) {
                &dprint("Searching for file: $path/$file\n");
                if (-f "$path/$file") {
                    &dprint("Found file: $file\n");
                    if (open(FILE, "$path/$file")) {
                        while(my $line = <FILE>) {
                            chomp($line);
                            $line =~ s/#.*//;
                            if (! $line) {
                                next;
                            }
                            my ($key, $value) = split(/\s*=\s*/, $line, 2);
                            push(@{$files{"$file"}{"$key"}}, &quotewords('[,\s]+', 0, $value));
                        }
                        close FILE;
                    } else {
                        &wprint("Could not open file: $path/$file: $!\n");
                    }
                }
            }
        }
        foreach my $key (keys %{$files{"$file"}}) {
            &dprint("Setting: $file:$key = ". @{$files{"$file"}{"$key"}} ."\n");
            $self->set($key, @{$files{"$file"}{"$key"}});
        }
    }

    return($self);
}


=head1 SEE ALSO



=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut



1;
