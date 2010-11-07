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
sub
new($$)
{
    my $proto               = shift;
    my @files               = @_;
    my $class               = ref($proto) || $proto;
    my $self                = ();
    my $main_config         = $Warewulf::Include::path{"SYSCONFDIR"} . "/warewulf/main.conf";
    my $progname_config     = $Warewulf::Include::path{"SYSCONFDIR"} . "/warewulf/" . $Warewulf::Include::info{"PROGNAME"} . ".conf";

    %{$self} = ();

    # Load up default configuration files
    if ( ! grep($_ eq $main_config, @{$self->{"FILE"}}) ) {
        push(@{$self->{"FILE"}}, $main_config);
    }
    if ( ! grep($_ eq $progname_config, @{$self->{"FILE"}}) ) {
        push(@{$self->{"FILE"}}, $progname_config);
    }

    if ( @files ) {
        push(@{$self->{"FILE"}}, @files);
    }

    bless($self, $class);

    $self->reread();

    return($self);
}

=item read

This will cause the configuration files to be reread.

=cut
sub
reread($)
{
    my $self                = shift;
    my @lines               = ();
    my %hash                = ();

    foreach my $file ( @{$self->{"FILE"}} ) {
        dprint("Looking for config file: $file\n");
        if ( -f $file ) {
            nprint("Reading config file: $file\n");
            open(FILE, $file);
            while(my $line = <FILE>) {
                my ($key, $value) = split(/\s*=\s*/, $line, 2);
                push(@{$self->{"DATA"}{"$key"}}, $value);
            }
            close FILE;
        } else {
            dprint("Config file not found: $file\n");
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

=back

=head1 SEE ALSO

Warewulf

=cut


1;
