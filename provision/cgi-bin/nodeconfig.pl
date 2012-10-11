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
use Warewulf::Node;
use Warewulf::Logger;
use Warewulf::Object;
use Warewulf::ObjectSet;

my $db = Warewulf::DataStore->new();
my $q = CGI->new();
my $hwaddr = $q->param('hwaddr');

print $q->header();

if ($hwaddr =~ /^([a-zA-Z0-9:]+)$/) {
    my $hwaddr = $1;
    my $nodeSet = $db->get_objects("node", "_hwaddr", $hwaddr);
    my $node = $nodeSet->get_object(0);
    my %nhash;

    if (! $node) {
        &eprint("Node with hardware address \"$hwaddr\" does not exist!");
        exit;
    }

    %nhash = $node->get_hash();
    foreach my $key (keys %nhash) {
        my $uc_key = uc($key);
        my $val;

        # Sanitize $uc_key to only contain characters which are valid
        # in the name of a shell variable for bash and POSIX sh.
        $uc_key =~ s/\W//g;

        # For arrays, print the first element.  Otherwise, print the value.
        if (ref($nhash{"$key"}) eq "ARRAY") {
            $val = join(",", @{$nhash{$key}});
        } elsif (ref(\$nhash{"$key"}) eq "SCALAR") {
            $val = $nhash{$key};
        } elsif (ref($nhash{"$key"}) eq "Warewulf::ObjectSet") {
            my @names;
            foreach my $o ($nhash{"$key"}->get_list()) {
                my $n = $o->get("name");
                if (defined($n)) {
                    push(@names, $n);
                }
            }
            $val = join(",", @names);
        } else {
            $val = "";
        }
        print "WW$uc_key=\"$val\"\nexport WW$uc_key\n";
    }
}

