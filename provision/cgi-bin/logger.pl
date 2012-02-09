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
use Warewulf::EventHandler;
use Sys::Syslog;

my $q = CGI->new();
my $db = Warewulf::DataStore->new();
my $eh = Warewulf::EventHandler->new();

print $q->header();

$eh->disable();

my $hwaddr = $q->param('hwaddr');
my $log = $q->param('log');
my $status = $q->param('status');

if ($hwaddr =~ /^([a-zA-Z0-9:]+)$/) {
    my $hwaddr = $1;
    my $nodeSet = $db->get_objects("node", "_hwaddr", $hwaddr);
    my $node = $nodeSet->get_object(0);
    my $name = $node->get("name") || $hwaddr;
    my ($sec, $min, $hr, $day, $mon, $year) = localtime;
    my $persist_bool;
    $year += 1900;
    my $timestamp = sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $year, $mon, $day, $hr, $min, $sec);
    my @log_line;
    if ($status =~ /^([a-zA-Z0-9\s\-_\.\/:\!\?\,]+)$/) {
        $node->set("_provisionstatus", $1);
        $persist_bool = 1;
    }
    if ($log =~ /^([a-zA-Z0-9\s\-_\.\/:\!\?\,]+)$/) {
        $node->set("_provisionlog", $1);
        openlog("wwprovision", "ndelay,pid", "local0");
        syslog("info", "$name $1");
        $persist_bool = 1;
    }
    if ($persist_bool) {
        $node->set("_provisiontime", time());
        $db->persist($node);
    }
}

