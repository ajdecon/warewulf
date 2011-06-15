#!/usr/bin/perl
#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#


use CGI;
use Warewulf::DataStore;
use Warewulf::DSOFactory;
use File::Path;

my $q = CGI->new();
my $db = Warewulf::DataStore->new();

print $q->header();

my $hwaddr = $q->param('hwaddr');
my $message = $q->param('message');

my $logdir = "/tmp/warewulf_log/provision/";

if (! -f $logdir) {
    mkpath($logdir);
}

if ($hwaddr =~ /^([a-zA-Z0-9:]+)$/) {
    my $hwaddr = $1;
    if ($message =~ /^([a-zA-Z0-9\s\-_\.\/:]+)$/) {
        my $nodeSet = $db->get_objects("node", "hwaddr", $hwaddr);
        my $node = $nodeSet->get_object(0);
        my $name = $node->get("name") || $hwaddr;
        my ($sec, $min, $hr, $day, $mon, $year) = localtime;
        my $timestamp = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
            $year, $mon, $day, $hr, $min, $sec);
        $node->set("_provisionlog", $message);
        $db->persist($node);
        open(LOG, ">> $logdir/$name.log");
        print LOG "[$timestamp] $message\n";
        close LOG;
    } else {
        warn "bad message from $hwaddr\n";
    }
}

