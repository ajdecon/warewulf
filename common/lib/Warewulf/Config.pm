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

=head1 SYNOPSIS

    use Warewulf::Config;

    my $obj = Warewulf::Config->new("something.conf");

    foreach my $entry ( $obj->get("config entry name") ) {
        print "->$entry<-\n";
    }

=head1 DESCRIPTION

The Warewulf::Config class allows one to access configuration paramaters
with an object interface.

=head1 FORMAT

The configuration file format utilizes key-value pairs separated by an
equal sign ('='). There maybe multiple key-value pairs as well as
comma-delimited value entries.

Line continuations are allowed as long as the previous line entry ends
with a backslash.

Example configuration directives:

    key = value one, value two, "value two,a"
    key = value three, \
          value four

This will assign the following to the "key" variable:

    value one
    value two
    value two,a
    value three
    value four


=head1 METHODS

=over 4

=item new($config_name)

The new() constructor will create the object that references the
configuration store. You can pass a list of configuration files that
will be included in the object if desired. Each config will be
searched for first in the user's home/private directory and then in
the global locations.

=cut

my %files;

sub
new()
{
    my ($proto, @args) = @_;
    my $class = ref($proto) || $proto;

    $self = $class->SUPER::new();
    bless($self, $class);

    return($self->parse(@args));
}

sub
parse()
{
    my ($self, @args) = @_;
    my @basepaths;

    
    @basepaths = (
        (getpwuid($>))[7] . "/.warewulf",
        &wwconfig("SYSCONFDIR") . "/warewulf"
    );

    foreach my $file (@args) {
        if (exists($files{"$file"})) {
            &dprint("Using cached configuration file:  $file\n");
        } else {
            foreach my $path (@basepaths) {
                &dprint("Searching for file:  $path/$file\n");
                if (-f "$path/$file") {
                    &dprint("Found file:  $file\n");
                    if (open(FILE, "$path/$file")) {
                        while(my $line = <FILE>) {
                            chomp($line);
                            $line =~ s/#.*//;
                            if (! $line) {
                                next;
                            }
                            my ($key, $value) = split(/\s*=\s*/, $line, 2);
                            push(@{$files{$file}{$key}}, grep { defined($_) } &quotewords('[,\s]+', 0, $value));
                        }
                        close(FILE);
                    } else {
                        &wprint("Could not open file $path/$file:  $!\n");
                    }
                }
            }
        }
        foreach my $key (keys(%{$files{$file}})) {
            $self->set($key, @{$files{$file}{$key}});
        }
    }

    return($self);
}

=back

=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut



1;
