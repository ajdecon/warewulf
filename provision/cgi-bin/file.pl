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
use Warewulf::Logger;
use Warewulf::Daemon;

&daemonized(1);

my $q = CGI->new();
my $db = Warewulf::DataStore->new();

print $q->header("text/plain");

my $hwaddr = $q->param('hwaddr');
my $fileid = $q->param('fileid');
my $node;

if ($hwaddr =~ /^([a-zA-Z0-9:]+)$/) {
    $hwaddr = $1;

    $node = $db->get_objects("node", "_hwaddr", $hwaddr)->get_object(0);

    if ($node) {
        if (! $fileid and $node) {
            my $nodeName = $node->get("name");

            foreach my $file ($node->get("fileids")) {
                if (! $file) {
                    next;
                }
                my $objSet = $db->get_objects("file", "_id", $file);
                foreach my $obj ($objSet->get_list()) {
                    if ($obj) {
                        printf("%s %s %s %s %s %s\n",
                            $obj->get("_id") || "NULL",
                            $obj->get("name") || "NULL",
                            $obj->get("uid") || "0",
                            $obj->get("gid") || "0",
                            $obj->get("mode") || "0000",
                            $obj->get("path") || "NULL");
                    }
                }
            }
        } elsif ($fileid =~ /^([0-9]+)$/ ) {
            $fileid = $1;
            my $output;
            my $fileObj = $db->get_objects("file", "_id", $fileid)->get_object(0);;
            my %nhash = $node->get_hash();

            if ($fileObj) {
                my $binstore = $db->binstore($fileObj->get("_id"));
                while(my $buffer = $binstore->get_chunk()) {
                    $output .= $buffer;
                }

                # Search for all matching variable entries.
                #foreach my $wwstring ($output =~ m/\%\{[^\}]+\}(\[([0-9]+)\])?/g) {
                foreach my $wwstring ($output =~ m/\%\{[^\}]+\}(?:\[\d+\])?/g) {
                    # Check for format, and seperate into a seperate wwvar string
                    if ($wwstring =~ /^\%\{(.+?)\}(\[(\d+)\])?$/) {
                        my $wwvar = $1;
                        my $wwarrayindex = $3;
                        # Set the current object that we are looking at. This is
                        # important as we iterate through multiple levels.
                        my $curObj = $node;
                        my @keys = split(/::/, $wwvar);
                        while(my $key = shift(@keys)) {
                            my $val = $curObj->get($key);
                            if (ref($val) eq "ARRAY") {
                                if (defined($wwarrayindex)) {
                                    # If the person defined an array index as part of the
                                    # variable, then give that.
                                    my $value = $val->[$wwarrayindex];
                                    $output =~ s/\Q$wwstring\E/$value/g;
                                } else {
                                    # If the value is an array, We need to iterate
                                    # through the array.
                                    foreach my $a (@{$val}) {
                                        if (ref($a) =~ /^Warewulf::DSO::/) {
                                            # Check to see if the array entry is a Data
                                            # Store Object (DSO), and if it is, then reset
                                            # the $curObj, and start over.
                                            my $name = $keys[0];
                                            if (uc($a->get("name")) eq uc($name)) {
                                                $curObj = $a;
                                                # Since we found this and used the current key
                                                # we need to shift the array.
                                                shift(@keys);
                                                last;
                                            }
                                        } elsif ($a) {
                                            $output =~ s/\Q$wwstring\E/$a/g;
                                        } else {
                                            $output =~ s/\Q$wwstring\E//g;
                                        }
                                    }
                                }
                            } elsif ($val) {
                                # Same logic as above just without the array contexts.
                                if (ref($a) =~ /^Warewulf::DSO::/) {
                                    my $name = shift(@keys);
                                    if (uc($a->get("name")) eq uc($name)) {
                                        $curObj = $a;
                                    }
                                } else {
                                    $output =~ s/\Q$wwstring\E/$val/g;
                                }
                            } else {
                                $output =~ s/\Q$wwstring\E//g;
                            }
                        }
                    }
                }
            }
            print $output;

        } else {
            &wprint("FILEID contains illegal characters\n");
        }
    } else {
        &wprint("Unknown HWADDR ID\n");
    }
} else {
    &wprint("HWADDR needs to be defined\n");
}
