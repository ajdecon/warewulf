#!/usr/bin/perl
#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#


use CGI;
use File::Path;
use Warewulf::DataStore;
use Warewulf::Logger;
use Warewulf::Daemon;
use Warewulf::Node;
use Warewulf::File;

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
            my $nodeName = $node->name();

            foreach my $file ($node->get("fileids")) {
                if (! $file) {
                    next;
                }
                my $objSet = $db->get_objects("file", "_id", $file);
                foreach my $obj ($objSet->get_list()) {
                    if ($obj) {
                        printf("%s %s %s %s %04o %s %s\n",
                            $obj->id() || "NULL",
                            $obj->name() || "NULL",
                            $obj->uid() || "0",
                            $obj->gid() || "0",
                            $obj->mode() || "0000",
                            $obj->checksum() || "nosum",
                            $obj->path() || "NULL"
                        );
                    }
                }
            }
        } elsif ($fileid =~ /^([0-9]+)$/ ) {
            $fileid = $1;
            my $output;

            my $fileObj = $db->get_objects("file", "_id", $fileid)->get_object(0);;

            if ($fileObj) {
                my $cachefile = "/tmp/warewulf/files/". $fileObj->id() ."/". $fileObj->checksum();

                if (! -f $cachefile) {
                    mkpath("/tmp/warewulf/files/". $fileObj->name());
                    $fileObj->file_export($cachefile);
                }

                if (open(CACHE, $cachefile)) {
                    while(my $line = <CACHE>) {
                        $output .= $line;
                    }
                    close CACHE;
                }

                # Search for all matching variable entries.
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
                            if (ref($val) eq "Warewulf::ObjectSet") {
                                my $find = shift(@keys);
                                my $o = $val->find("name", $find);
                                if ($o) {
                                    $curObj = $o;
                                } else {
                                    &dprint("Could not find object: $find\n");
                                }

                            } elsif (ref($val) eq "ARRAY") {
                                my $v;
                                if ($wwarrayindex) {
                                    $v = $val->[$wwarrayindex];
                                } else {
                                    $v = $val->[0];
                                }
                                $output =~ s/\Q$wwstring\E/$v/g;
                            } elsif ($val) {
                                $output =~ s/\Q$wwstring\E/$val/g;
                            } else {
                                $output =~ s/\Q$wwstring\E//g;
                            }
                        }
                    }
                }
            }

            if ($fileObj->interpreter()) {
                my $interpreter = $fileObj->interpreter();
                #FIXME: Perhaps use open3 here?
                if (open(PIPE, "| $interpreter")) {
                    print PIPE $output;
                    close PIPE;
                }
            } else {
                print $output;
            }

        } else {
            &wprint("FILEID contains illegal characters\n");
        }
    } else {
        &wprint("Unknown HWADDR ID\n");
    }
} else {
    &wprint("HWADDR needs to be defined\n");
}
