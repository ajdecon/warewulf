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
use Warewulf::ObjectFactory;

my $q = CGI->new();
my $db = Warewulf::DataStore->new();

sub
print_vnfs()
{
    my $vnfs_name = shift;

    my $vnfs = $db->get_objects("vnfs", "name", $vnfs_name)->get_object(0);
    if ($vnfs) {
        print "Content-Type:application/octet-stream; name=\"vnfs.img\"\r\n";
        if (my $size = $vnfs->get("size")) {
            print "Content-length: $size\r\n";
        }
        print "Content-Disposition: attachment; filename=\"vnfs.img\"\r\n";
        print "\r\n";
        my $vnfs_binstore = $db->binstore($vnfs->get("id"));
        while(my $buffer = $vnfs_binstore->get_chunk()) {
            print $buffer;
        }
        return(1);
    }

    return();
}


if ($q->param('name')) {
    &print_vnfs($q->param('name'));
} elsif ($q->param('hwaddr')) {
    my $hwaddr = $q->param('hwaddr');
    my $nodeSet = $db->get_objects("node", "hwaddr", $hwaddr);
    my $node = $nodeSet->get_object(0);
    if ($node) {
        my @vnfs_array = $node->get("vnfs");
        if (@vnfs_array) {
            foreach my $vnfs_name (@vnfs_array) {
                &print_vnfs($vnfs_name);
            }
        } else {
            &eprint($node->get("name") ." has no VNFS set\n");
        }
    }
}
