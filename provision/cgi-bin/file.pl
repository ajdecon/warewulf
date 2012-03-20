#!/usr/bin/perl
#
# Copyright (c) 2001-2003 Gregory M. Kurtzer
#
# Copyright (c) 2003-2011, The Regents of the University of California,
# through Lawrence Berkeley National Laboratory (subject to receipt of any
# required approvals from the U.S. Dept. of Energy).  All rights reserved.
#


use CGI;
use Digest::MD5 ('md5_hex');
use File::Path;
use IPC::Open2;
use Warewulf::DataStore;
use Warewulf::Logger;
use Warewulf::Daemon;
use Warewulf::Node;
use Warewulf::File;
use Warewulf::DSO::File;

&daemonized(1);

my $q = CGI->new();
my $db = Warewulf::DataStore->new();

print $q->header("text/plain");

my $hwaddr = $q->param('hwaddr');
my $fileid = $q->param('fileid');
my $timestamp = $q->param('timestamp');
my $node;

if ($hwaddr =~ /^([a-zA-Z0-9:]+)$/) {
    $hwaddr = $1;

    $node = $db->get_objects("node", "_hwaddr", $hwaddr)->get_object(0);

    if ($node) {

        if (! $fileid and $node) {
            my $nodeName = $node->name();
            my %metadata;

            foreach my $file ($node->get("fileids")) {
                if (! $file) {
                    next;
                }
                my $objSet = $db->get_objects("file", "_id", $file);
                foreach my $obj ($objSet->get_list()) {
                    if ($obj) {
                        my $obj_timestamp = $obj->timestamp() || 0;
                        if ($timestamp and $timestamp >= $obj_timestamp) {
                            next;
                        }
                        $metadata{$obj_timestamp} = sprintf("%s %s %s %s %04o %s %s\n",
                            $obj->id() || "NULL",
                            $obj->name() || "NULL",
                            $obj->uid() || "0",
                            $obj->gid() || "0",
                            $obj->mode() || "0000",
                            $obj_timestamp,
                            $obj->path() || "NULL"
                        );
                    }
                }
            }
            foreach my $t (sort {$a <=> $b} keys %metadata) {
                print $metadata{$t};
            }
        } elsif ($fileid =~ /^([0-9]+)$/ ) {
            $fileid = $1;
            my $read_buffer;
            my $send_buffer;

            my $fileObj = $db->get_objects("file", "_id", $fileid)->get_object(0);;

            if ($fileObj) {
                my $cachefile = "/tmp/warewulf/files/". $fileObj->id() ."/". $fileObj->checksum();

                if (! -f $cachefile) {
                    mkpath("/tmp/warewulf/files/". $fileObj->name());
                    $fileObj->file_export($cachefile);
                }

                if (open(CACHE, $cachefile)) {
                    while(my $line = <CACHE>) {
                        $read_buffer .= $line;
                    }
                    close CACHE;
                }

                # Search for all matching variable entries.
                foreach my $wwstring ($read_buffer =~ m/\%\{[^\}]+\}(?:\[\d+\])?/g) {
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
                                $read_buffer =~ s/\Q$wwstring\E/$v/g;
                            } elsif ($val) {
                                $read_buffer =~ s/\Q$wwstring\E/$val/g;
                            } else {
                                $read_buffer =~ s/\Q$wwstring\E//g;
                            }
                        }
                    }
                }
            }

            if ($fileObj->interpreter()) {
                my $interpreter = $fileObj->interpreter();
                my $pipe_in;
                my $pipe_out;
                eval {
                    local $SIG{ALRM} = sub { die "DIED ON ALARM CALLING: $interpreter\n" };
                    alarm 1;
                    my $pid = open2($pipe_out, $pipe_in, "$interpreter");
                    if ($pid) {
                        print $pipe_in $read_buffer;
                        close $pipe_in;
                        while(my $line = <$pipe_out>) {
                            $send_buffer .= $line;
                        }
                        close $pipe_out;
                    }
                    alarm 0;
                };
                if ($@) {
                    &eprint("Failed calling interpreter: $intrepreter\n");
                    $send_buffer = undef;
                }
            } elsif ($read_buffer) {
                $send_buffer = $read_buffer;
            }

            if ($send_buffer) {
                print $send_buffer;
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
