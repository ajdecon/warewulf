# Warewulf node object
#
# Michael Jennings <mej@lbl.gov>
# 09 August 2010
#
# Copyright (c) 2010, The Regents of the University of California, through
# Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# $Id: Node.pm 8 2010-08-17 00:28:29Z mej $
#

package Warewulf::Node;
use POSIX;
use IO::Socket::INET;
#use Warewulf::Util;
use Warewulf::Node;

sub
new($)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self;

    $self = {};
    bless($self, $class);
    return $self->init(@_);
}

sub
init(@)
{
    my ($self, $name, $ip) = @_;

    $self->{"NAME"} = $name;
    $self->{"IP"} = $ip || "";

    # This will contain the wulfd data for the node.
    $self->{"DATA"} = {};
    return $self;
}

sub
get($)
{
    my ($self, @keys) = @_;
    my @values;

    dprint &print_args(@_);
    foreach my $key (@keys) {
        if ($key !~ /^\w+$/) {
            push @values, undef;
        } elsif (exists($self->{$key})) {
            push @values, $self->{$key};
        } elsif (exists($self->{"DATA"}{$key})) {
            push @values, $self->{"DATA"}{$key};
        } else {
            push @values, undef;
        }
    }
    dprintf("Returning \"%s\".\n", join(", ", map { ((defined($_)) ? ($_) : ("<undef>")) } @values));
    if (wantarray()) {
        return @values;
    } else {
        return $values[0];
    }
}

sub
set($$)
{
    my ($self, %pairs) = @_;
    my $final;

    dprint &print_args(@_);
    foreach my $key (keys(%pairs)) {
        if ($key !~ /^\w+$/) {
            $final = undef;
        } elsif (exists($self->{$key})) {
            $final = $self->{$key} = $pairs{$key};
        } elsif (exists($self->{"DATA"}{$key})) {
            $final = $self->{"DATA"}{$key} = $pairs{$key};
        } else {
            $final = undef;
        }
    }
    dprintf("Returning %s.\n", ((defined($final)) ? ($final) : ("<undef>")));
    return $final;
}

sub
to_string()
{
    my $self = shift;

    return "$self->{NAME}" . (($self->{"IP"}) ? ("[$self->{IP}]") : (""));
}

1;
