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

my $nodeSet = $db->get_objects("node", "hwaddr", $hwaddr);
my $node = $nodeSet->get_object(0);

if ($node) {
    my $nodeName = $node->get("name");
} else {
    $node = Warewulf::DSOFactory->new("node");
    $node->set("name", "newnode");
    $node->set("hwaddr", $hwaddr);
    $db->persist($node);
}

foreach my $script ($node->get("bootscript")) {
    if (! $script) {
        next;
    }
    my $s = $db->get_objects("script", "name", $script);
    my $sobj = $s->get_object(0);
    my $sbinstore = $db->binstore($sobj->get("id"));
    my $script;
    my %nhash = $node->get_hash();
    while(my $buffer = $sbinstore->get_chunk()) {
        print $buffer;
    }
}
