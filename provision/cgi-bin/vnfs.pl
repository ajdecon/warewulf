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
            my ($vnfs) = $node->get("vnfs");
            if ($vnfs) {
                my $obj = $db->get_objects("vnfs", "name", $vnfs)->get_object(0);
                if ($obj) {
                    print "Content-Type:application/octet-stream; name=\"vnfs.img\"\r\n";
                    if (my $size = $obj->get("size")) {
                        print "Content-length: $size\r\n";
                    }
                    print "Content-Disposition: attachment; filename=\"vnfs.img\"\r\n";
                    print "\r\n";
                    my $binstore = $db->binstore($obj->get("id"));
                    while(my $buffer = $binstore->get_chunk()) {
                        print $buffer;
                    }
                } else {
                    &eprint("VNFS request for an unset VNFS\n");
                    print "Content-Type:application/octet-stream\r\n";
                    print "Status: 404\r\n";
                    print "\r\n";
                }
            } else {
                &eprint($node->get("name") ." has no VNFS set\n");
                print "Content-Type:application/octet-stream\r\n";
                print "Status: 404\r\n";
                print "\r\n";
            }
        } else {
            &eprint("VNFS request for an unknown node\n");
            print "Content-Type:application/octet-stream\r\n";
            print "Status: 404\r\n";
            print "\r\n";
        }
    } else {
        &eprint("VNFS request for a bad hwaddr\n");
        print "Content-Type:application/octet-stream\r\n";
        print "Status: 404\r\n";
        print "\r\n";
    }
} else {
    &eprint("VNFS request without a hwaddr\n");
    print "Content-Type:application/octet-stream\r\n";
    print "Status: 404\r\n";
    print "\r\n";
}



