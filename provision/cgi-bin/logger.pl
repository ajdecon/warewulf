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
my $log = $q->param('log');
my $status = $q->param('status');

my $logdir = "/tmp/warewulf_log/provision/";

if (! -f $logdir) {
    mkpath($logdir);
}

if ($hwaddr =~ /^([a-zA-Z0-9:]+)$/) {
    my $hwaddr = $1;
    my $nodeSet = $db->get_objects("node", "hwaddr", $hwaddr);
    my $node = $nodeSet->get_object(0);
    my $name = $node->get("name") || $hwaddr;
    my ($sec, $min, $hr, $day, $mon, $year) = localtime;
    $year += 1900;
    my $timestamp = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $year, $mon, $day, $hr, $min, $sec);
    my @log_line;
    open(LOG, ">> $logdir/$name.log");
    if ($status =~ /^([a-zA-Z0-9\s\-_\.\/:\!\?\,]+)$/) {
        $node->set("_provisionstatus", $1);
        print LOG "[$timestamp] STATUS=$1\n";
    }
    if ($log =~ /^([a-zA-Z0-9\s\-_\.\/:\!\?\,]+)$/) {
        $node->set("_provisionlog", $1);
        print LOG "[$timestamp] LOG=$1\n";
    }
    $node->set("_provisiontime", time());
    $db->persist($node);
    close LOG;
}

