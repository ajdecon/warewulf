# Warewulf timer object
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
# $Id: Timer.pm 8 2010-08-17 00:28:29Z mej $
#

package Warewulf::Timer;
use POSIX;
use Time::HiRes ('gettimeofday');
#use Warewulf::Util;
use Warewulf::Event;

# Use global singleton for timer queue.
my $singleton;

sub
new($)
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    if ($singleton) {
        return $singleton;
    }
    $singleton = {};
    bless($singleton, $class);
    return $singleton->init(@_);
}

sub
init(@)
{
    my $self = shift;

    # Initialize to an empty list to start.
    $self->{"QUEUE"} = [];
    return $self;
}

sub
add_event($)
{
    my $self = shift;
    my $queue = $self->{"QUEUE"};
    my $event;

    if (ref($_[0])) {
        # If we were passed a reference, assume it's an Event object.
        $event = shift;
    } else {
        # Otherwise, assume we got parameters to create an Event object.
        $event = Warewulf::Event->new(@_);
    }

    # Insert Event object into queue.  This is an insertion sort, meaning
    # that we maintain the queue in order sorted by TIME from earliest to
    # latest.  This keeps the next Event to be triggered always at the
    # front of the queue where it can be retrieved quickly.
    for (my $i = 0; $i < scalar(@{$queue}); $i++) {
        if ($event->time() < $queue->[$i]->time()) {
            splice(@{$queue}, $i, 0, $event);
            return $i;
        }
    }
    # If no events in the queue were later than this one, tack it onto the end.
    push @{$queue}, $event;
    return $#{$queue};
}

sub
del_event($)
{
    my ($self, $name) = @_;
    my $queue = $self->{"QUEUE"};

    for (my $i = 0; $i < scalar(@{$queue}); $i++) {
        my $event = $queue->[$i];

        if ($event->name() eq $name) {
            splice(@{$queue}, $i, 1);
            return $event;
        }
    }
    return undef;
}

sub
next_event()
{
    my $self = shift;

    return ((scalar(@{$self->{"QUEUE"}})) ? ($self->{"QUEUE"}[0]) : (undef));
}

sub
timeout()
{
    my $self = shift;
    my ($curtime, $evtime);

    if (!scalar(@{$self->{"QUEUE"}})) {
        # Empty queue.  Timeout next year.
        return 31536000;
    }
    $curtime = gettimeofday();
    $evtime = $self->{"QUEUE"}[0]->time();
    if ($curtime > $evtime) {
        # The next event is already overdue.
        return 0;
    } else {
        return ($evtime - $curtime);
    }
}

sub
run()
{
    my $self = shift;
    my $curtime = gettimeofday();
    my $queue = $self->{"QUEUE"};
    my $cnt;

    for ($cnt = 0; scalar(@{$queue}) && ($queue->[0]->time() < $curtime); $cnt++) {
        my $event = $queue->[0];

        $event->trigger();
        if ($event == $queue->[0]) {
            # The callback may have moved/removed the event, so check before deleting.
            shift @{$queue};
        }
    }
    return $cnt;
}

sub
to_string()
{
    my $self = shift;

    if (scalar(@{$self->{"QUEUE"}})) {
        my $queue = $self->{"QUEUE"};

        return sprintf("Timer Queue [%d events, next:  %s]", scalar(@{$queue}), $queue->[0]->to_string());
    } else {
        return "Timer Queue [empty]";
    }
}

1;
