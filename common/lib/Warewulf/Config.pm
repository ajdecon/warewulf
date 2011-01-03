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
use Text::ParseWords;

use Exporter;

our @ISA = ('Exporter');

our @EXPORT = ();

=head1 NAME

Warewulf::Config - Object interface to configuration paramaters

=head1 ABOUT

The Warewulf::Config class allows one to access configuration paramaters
with as an object interface.

=head1 SYNOPSIS

    use Warewulf::Config;

    my $obj = Warewulf::Config->new();

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


=item new([path to config])

The new constructor will create the object that references configuration the
stores. You can pass a list of configuration files that will be included in
the object if desired.

Some configuration files will automatically be included in the following
order:

    /etc/warewulf/[program name].conf
    /etc/warewulf/main.conf

(assumg that warewulf was built with --sysconfdir=/etc/)

=cut

my %file_data;


sub
new($$)
{
    my ($proto, @files) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};

    &dprint("Creating new object\n");

    foreach my $file (@files) {
        my $path = $Warewulf::Include::wwconfig{"SYSCONFDIR"} . "/warewulf/" . $file;
        $self->{"FILES"}{"$file"} = $path;
    }

    bless($self, $class);

    $self->read();

    return($self);
}

=item read

This will cause the configuration files to be reread.

=cut
sub
read($)
{
    my ($self) = @_;

    foreach my $file (keys %{$self->{"FILES"}}) {
        my $path = $self->{"FILES"}{"$file"};
        if (exists($file_data{"$path"})) {
            &dprint("Using cached copy of file: $path\n");
        } else {
            &iprint("Reading in file: $path\n");
            if (-f $path) {
                if (open(FILE, $path)) {
                    while(my $line = <FILE>) {
                        chomp($line);
                        $line =~ s/#.*//;
                        if (! $line) {
                            next;
                        }
                        my ($key, $value) = split(/\s*=\s*/, $line, 2);
                        push(@{$file_data{"$path"}{"$key"}}, $value);
                    }
                    close FILE;
                } else {
                    &eprint("Could not open configuration file: $path ($!)\n");
                }
            } else [
                &eprint("Configuration file not found: $path\n");
            }
        }
        foreach my $key (keys %{$file_data{"$path"}}) {
            push(@{$self->{"DATA"}{"$key"}}, @{$file_data{"$path"}{"$key"}});
        }
    }

    return();
}

=item get(config key)

This will read from the configuration object and return the values of the key
specified. If this method is called in a scalar context it will return the
first match found. Otherwise it will return an array of all matches.

=cut
sub
get($$)
{
    my $self                = shift;
    my $key                 = shift;
    my @values              = ();
    my $string              = ();

    if ( $key ) {
        if (exists($self->{"DATA"}{"$key"})) {
            push(@values, @{$self->{"DATA"}{"$key"}});
        }
    } else {
        return();
    }

    if ( wantarray ) {
        return(@values);
    } else {
        return($values[0]);
    }
}


=head1 SEE ALSO



=head1 COPYRIGHT

Copyright (c) 2001-2003 Gregory M. Kurtzer

Copyright (c) 2003-2011, The Regents of the University of California,
through Lawrence Berkeley National Laboratory (subject to receipt of any
required approvals from the U.S. Dept. of Energy).  All rights reserved.

=cut



1;
