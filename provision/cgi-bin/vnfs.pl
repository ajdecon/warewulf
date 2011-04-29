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
use Warewulf::Logger;
use Warewulf::Daemon;

&daemonized(1);

my $q = CGI->new();
my $db = Warewulf::DataStore->new();


if ($q->param('hwaddr')) {
    my $hwaddr = $q->param('hwaddr');
    if ($hwaddr =~ /^([a-zA-Z0-9:]+)$/) {
        my $hwaddr = $1;
        my $nodeSet = $db->get_objects("node", "hwaddr", $hwaddr);
        my $node = $nodeSet->get_object(0);
        if ($node) {
            my ($node_name) = $node->get("name");
            my ($vnfsid) = $node->get("vnfsid");
            if ($vnfsid) {
                my $obj = $db->get_objects("vnfs", "id", $vnfsid)->get_object(0);
                if ($obj) {
                    my ($vnfs_name) = $obj->get("name");
                    &nprint("Sending VNFS '$vnfs_name' to node '$node_name'\n");
                    $q->print("Content-Type:application/octet-stream; name=\"vnfs.img\"\r\n");
                    if (my $size = $obj->get("size")) {
                        $q->print("Content-length: $size\r\n");
                    }
                    $q->print("Content-Disposition: attachment; filename=\"vnfs.img\"\r\n");
                    $q->print("\r\n");
                    my $binstore = $db->binstore($obj->get("id"));
                    while(my $buffer = $binstore->get_chunk()) {
                        $q->print($buffer);
                    }
                } else {
                    &eprint("VNFS request for an unset VNFS\n");
                    $q->print("Content-Type:application/octet-stream\r\n");
                    $q->print("Status: 404\r\n");
                    $q->print("\r\n");
                }
            } else {
                &eprint($node->get("name") ." has no VNFS set\n");
                $q->print("Content-Type:application/octet-stream\r\n");
                $q->print("Status: 404\r\n");
                $q->print("\r\n");
            }
        } else {
            &eprint("VNFS request for an unknown node\n");
            $q->print("Content-Type:application/octet-stream\r\n");
            $q->print("Status: 404\r\n");
            $q->print("\r\n");
        }
    } else {
        &eprint("VNFS request for a bad hwaddr\n");
        $q->print("Content-Type:application/octet-stream\r\n");
        $q->print("Status: 404\r\n");
        $q->print("\r\n");
    }
} else {
    &eprint("VNFS request without a hwaddr\n");
    $q->print("Content-Type:application/octet-stream\r\n");
    $q->print("Status: 404\r\n");
    $q->print("\r\n");
}



