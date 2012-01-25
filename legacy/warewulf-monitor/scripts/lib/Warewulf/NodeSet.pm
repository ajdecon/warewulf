# Warewulf node set (i.e., master node) object
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
# $Id: NodeSet.pm 8 2010-08-17 00:28:29Z mej $
#

package Warewulf::NodeSet;
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
    $self->{"IP"} = $ip;

    # Keep sorted list.
    $self->{"NODES"} = [];

    # Initialize lookup tables to empty.
    $self->{"BY_NAME"} = {};
    $self->{"BY_IP"} = {};
    return $self;
}

sub
get($)
{
    my ($self, @keys) = @_;
    my @values;

    dprint &print_args(@_);
    foreach my $key (@keys) {
        if (($key !~ /^\w+$/) || (!exists($self->{$key}))) {
            push @values, undef;
        } else {
            push @values, $self->{$key};
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
        if (($key !~ /^\w+$/) || (!exists($self->{$key}))) {
            $final = undef;
        } elsif (defined($pairs{$key})) {
            $final = $self->{$key} = $pairs{$key};
        }
    }
    dprintf("Returning %s.\n", ((defined($final)) ? ($final) : ("<undef>")));
    return $final;
}

sub
add($)
{
    my ($self, $node) = @_;
    my $nodes = $self->{"NODES"};
    my ($name, $ip, $i);

    $name = $node->get("NAME");
    $self->{"BY_NAME"}{$name} = $node;
    $ip = $node->get("IP");
    if ($ip) {
        $self->{"BY_IP"}{$ip} = $node;
    } else {
        $ip = "<unknown ip>";
    }

    # This is basically an insertion sort for the sorted node list.
    for ($i = 0; $i < scalar(@{$nodes}); $i++) {
        my $this_name = $nodes->[$i]->get("NAME");

        if ($name lt $this_name) {
            #&dlog("Inserting new node $name ($ip) at position $i.");
            splice(@{$nodes}, $i, 0, $node);
            return $i;
        }
    }
    push @{$nodes}, $node;
    #&dlog("Appending new node $name ($ip) at end, position $i.");
    return $i;
}

sub
del($)
{
    my ($self, $node) = @_;
    my ($name, $ip);

    @{$self->{"NODES"}} = grep { $_ ne $node } @{$self->{"NODES"}};
    $name = $node->get("NAME");
    delete $self->{"BY_NAME"}{$name};
    $ip = $node->get("IP");
    if ($ip) {
        delete $self->{"BY_IP"}{$ip};
    }
}

sub
find_by_name($)
{
    my ($self, $name) = @_;

    if (exists($self->{"BY_NAME"}{$name})) {
        return $self->{"BY_NAME"}{$name};
    } else {
        return undef;
    }
}

sub
find_by_ip($)
{
    my ($self, $ip) = @_;

    if (exists($self->{"BY_IP"}{$ip})) {
        return $self->{"BY_IP"}{$ip};
    } else {
        return undef;
    }
}

sub
connect()
{
    my $self = shift;

    $self->{"SOCK"} = IO::Socket::INET->new("PeerAddr" => $self->{"IP"}, "PeerPort" => "warewulfd(9873)",
                                            "Type" => SOCK_STREAM, "Proto" => "tcp", "Timeout" => 0.05,
                                            "Blocking" => 0);
    return $self->{"SOCK"};
}

sub
recv()
{
    my $self = shift;
    my $sock = $self->{"SOCK"};
    my ($line, $node);

    if (! $sock) {
        # This would be very strange indeed.
        return undef;
    }
    while (defined($line = $sock->getline())) {
        my ($key, $value);

        chomp($line);
        if ($line =~ /^\s*(\w+)\s*=\s*(.*)\s*$/) {
            ($key, $value) = ($1, $2);
        } else {
            #&dprintf("Skipping unparseable line \"$line\"\n");
            next;
        }
        if (uc($key) eq "NODE") {
            $node = $self->find_by_name($value);
            if (! $node) {
                $node = Warewulf::NodeSet->new($value);
            }
        } else {
            $node->set($key, $value);
        }
    }

    # Done with socket.
    $sock->shutdown(2);
    delete $self->{"SOCK"};
}

sub
to_string()
{
    my $self = shift;

    return "NodeSet $self->{NAME} ($self->{IP})";
}

1;
