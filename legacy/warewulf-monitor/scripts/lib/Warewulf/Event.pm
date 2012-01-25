# Warewulf event object
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
# $Id: Event.pm 8 2010-08-17 00:28:29Z mej $
#

package Warewulf::Event;
use POSIX;
use Time::HiRes ('gettimeofday');
#use Warewulf::Util;

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
    my ($self, $name, $time, $callback, $data) = @_;
    my $curtime = scalar(gettimeofday());

    if ($time < $curtime) {
        $time += $curtime;
    }
    @{$self}{("NAME", "TIME", "CALLBACK")} = ($name, $time, $callback);
    if (defined($data)) {
        $self->{"DATA"} = $data;
    }
    return $self;
}

sub
name()
{
    my $self = shift;

    if (scalar(@_)) {
        $self->{"NAME"} = $_[0];
    }
    return $self->{"NAME"};
}

sub
time()
{
    my $self = shift;

    if (scalar(@_)) {
        $self->{"TIME"} = $_[0];
    }
    return $self->{"TIME"};
}

sub
callback()
{
    my $self = shift;

    if (scalar(@_)) {
        $self->{"CALLBACK"} = $_[0];
    }
    return $self->{"CALLBACK"};
}

sub
data()
{
    my $self = shift;

    if (scalar(@_)) {
        $self->{"DATA"} = $_[0];
    }
    return ((exists($self->{"DATA"})) ? ($self->{"DATA"}) : (undef));
}

sub
trigger()
{
    my $self = shift;

    return &{$self->{"CALLBACK"}}(((exists($self->{"DATA"})) ? ($self->{"DATA"}) : (undef)));
}

sub
to_string()
{
    my $self = shift;

    return POSIX::strftime("Event \"$self->{NAME}\" at %H:%M:%S %Y-%m-%d", localtime($self->{"TIME"}));
}

1;
