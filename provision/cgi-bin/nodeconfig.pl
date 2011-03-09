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

my $q = CGI->new();
my $db = Warewulf::DataStore->new();

print $q->header();

my $hwaddr = $q->param('hwaddr');

if ($hwaddr =~ /^([a-zA-Z0-9:]+)$/) {
    my $hwaddr = $1;
    my $nodeSet = $db->get_objects("node", "hwaddr", $hwaddr);
    my $node = $nodeSet->get_object(0);

    if (! $node) {
        $node = Warewulf::DSOFactory->new("node");
        $node->set("name", "newnode");
        $node->set("hwaddr", $hwaddr);
        $db->persist($node);
    }

    my %nhash = $node->get_hash();
    foreach my $key (keys %nhash) {
        my $uc_key = uc($key);
        my $val;
        if (ref($nhash{"$key"}) eq "ARRAY") {
            #print "$uc_key=\"'". join("'\" \"'", @{$nhash{"$key"}}) ."'\"\n";
            print "WW$uc_key=\"". join(" ", @{$nhash{"$key"}}) ."\"\n";
        } else {
            print "WW$uc_key=\"$nhash{$key}\"\n";
        }
        print "export WW$uc_key\n";
    }
}

