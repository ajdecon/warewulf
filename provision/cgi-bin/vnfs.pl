#!/usr/bin/perl
#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#


use CGI;
use Warewulf::Util;
use Warewulf::DataStore;
use Warewulf::Logger;
use Warewulf::Daemon;
use File::Path;
use File::Basename;

&daemonized(1);

my $q = CGI->new();
my $db = Warewulf::DataStore->new();

my $vnfs_cachedir = "/var/tmp/warewulf_cache/";


if ($q->param('hwaddr')) {
    my $hwaddr = $q->param('hwaddr');
    if ($hwaddr =~ /^([a-zA-Z0-9:]+)$/) {
        my $hwaddr = $1;
        my $nodeSet = $db->get_objects("node", "_hwaddr", $hwaddr);
        my $node = $nodeSet->get_object(0);
        if ($node) {
            my ($node_name) = $node->get("name");
            my ($vnfsid) = $node->get("vnfsid");
            if ($vnfsid) {
                my $obj = $db->get_objects("vnfs", "_id", $vnfsid)->get_object(0);
                if ($obj) {
                    my ($vnfs_name) = $obj->get("name");
                    my ($vnfs_checksum) = $obj->get("checksum");
                    my ($vnfs_nocache) = $obj->get("nocache");
                    my $use_cache;

                    #&nprint("Sending VNFS '$vnfs_name' to node '$node_name'\n");
                    $q->print("Content-Type: application/octet-stream; name=\"vnfs.img\"\r\n");
                    if (my $size = $obj->get("size")) {
                        $q->print("Content-length: $size\r\n");
                    }
                    $q->print("Content-Disposition: attachment; filename=\"vnfs.img\"\r\n");
                    $q->print("\r\n");

                    if (! $vnfs_nocache) {
                        if (-f "$vnfs_cachedir/$vnfs_name/image.$vnfs_checksum") {
                            &dprint("Found VNFS cache\n");
                            # Perhaps do a better job checking here... one day.
                            $use_cache = 1;
                        } else {
                            &dprint("Building VNFS cache\n");
                            my $rand = &rand_string(8);
                            my $cache_fh;

                            if (! -d "$vnfs_cachedir/$vnfs_name") {
                                mkpath("$vnfs_cachedir/$vnfs_name");
                            }
                            
                            open($cache_fh, "> $vnfs_cachedir/$vnfs_name/image.$vnfs_checksum.$rand");
                            my $binstore = $db->binstore($obj->get("_id"));

                            while(my $buffer = $binstore->get_chunk()) {
                                print $cache_fh $buffer;
                            }
                            if (close($cache_fh)) {
                                rename("$vnfs_cachedir/$vnfs_name/image.$vnfs_checksum.$rand", "$vnfs_cachedir/$vnfs_name/image.$vnfs_checksum");
                                foreach my $image (glob("$vnfs_cachedir/$vnfs_name/image.*")) {
                                    if ($image =~ /^([a-zA-Z0-9\/\-\._]+?\/image\.[a-zA-Z0-9]+)$/) {
                                        $image = $1;
                                        my $basename = basename($image);
                                        if ($basename ne "image.$vnfs_checksum") {
                                            &wprint("Clearing old vnfs cache: $image\n");
                                            unlink($image);
                                        }
                                    }
                                }
                                $use_cache = 1;
                            }
                        }
                    }

                    if ($use_cache) {
                        &dprint("Sending cached VNFS\n");
                        my $cache_fh;
                        if (open($cache_fh, "$vnfs_cachedir/$vnfs_name/image.$vnfs_checksum")) {
                            my $buffer;
                            while($buffer = <$cache_fh>) {
                                $q->print($buffer);
                            }
                            close($cache_fh);
                        } else {
                            &eprint("Can't open VNFS cache!\n");
                        }

                    } else {
                        &dprint("Sending VNFS from the datastore\n");
                        my $binstore = $db->binstore($obj->get("_id"));
                        while(my $buffer = $binstore->get_chunk()) {
                            $q->print($buffer);
                        }
                    }

                } else {
                    &eprint("VNFS request for an unset VNFS\n");
                    $q->print("Content-Type: application/octet-stream\r\n");
                    $q->print("Status: 404\r\n");
                    $q->print("\r\n");
                }
            } else {
                &eprint($node->get("name") ." has no VNFS set\n");
                $q->print("Content-Type: application/octet-stream\r\n");
                $q->print("Status: 404\r\n");
                $q->print("\r\n");
            }
        } else {
            &eprint("VNFS request for an unknown node\n");
            $q->print("Content-Type: application/octet-stream\r\n");
            $q->print("Status: 404\r\n");
            $q->print("\r\n");
        }
    } else {
        &eprint("VNFS request for a bad hwaddr\n");
        $q->print("Content-Type: application/octet-stream\r\n");
        $q->print("Status: 404\r\n");
        $q->print("\r\n");
    }
} else {
    &eprint("VNFS request without a hwaddr\n");
    $q->print("Content-Type: application/octet-stream\r\n");
    $q->print("Status: 404\r\n");
    $q->print("\r\n");
}



